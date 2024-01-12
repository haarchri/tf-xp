#!/bin/bash
set -e

kind create cluster --name=tf-xp --config=kind-config.yaml
kubectx kind-tf-xp

kubectl create namespace upbound-system
kubectl apply -f init/pv.yaml

helm install uxp --namespace upbound-system upbound-stable/universal-crossplane --devel --version 1.14.5-up.1
# setup local-storage and patch crossplane container
kubectl -n upbound-system patch deployment/crossplane --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/1","value":{"image":"alpine","name":"dev","command":["sleep","infinity"],"volumeMounts":[{"mountPath":"/tmp/cache","name":"package-cache"}]}},{"op":"add","path":"/spec/template/metadata/labels/patched","value":"true"}]'
kubectl -n upbound-system wait deploy crossplane --for condition=Available --timeout=60s
kubectl -n upbound-system wait pods -l app=crossplane,patched=true --for condition=Ready --timeout=60s

up xpkg build --ignore="init/*.yaml,examples/*.yaml,kind-config.yaml" --output=tf-xp.xpkg
up xpkg xp-extract --from-xpkg tf-xp.xpkg -o ./tf-xp.gz
kubectl -n upbound-system cp ./tf-xp.gz -c dev $(kubectl -n upbound-system get pod -l app=crossplane,patched=true -o jsonpath="{.items[0].metadata.name}"):/tmp/cache
kubectl apply -f init/configuration.yaml

kubectl -n upbound-system create secret generic aws-creds --from-literal=credentials="${CREDENTIALS}" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl wait configuration.pkg --all --for=condition=Healthy --timeout 5m
kubectl wait configuration.pkg --all --for=condition=Installed --timeout 5m
kubectl wait configurationrevisions.pkg --all --for=condition=Healthy --timeout 5m

kubectl wait provider.pkg --all --for condition=Healthy --timeout 5m
kubectl -n upbound-system wait --for=condition=Available deployment --all --timeout=5m
kubectl wait xrd --all --for condition=Established

cat <<EOF | kubectl apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    secretRef:
      key: credentials
      name: aws-creds
      namespace: upbound-system
    source: Secret
EOF

kubectl apply -f examples/claim.yaml