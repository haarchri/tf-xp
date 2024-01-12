# Terraform

- aws credentials from default path will be used

```bash
cd tf
terraform init
terraform plan
```

# Crossplane

* the setup script will setup a crossplane environment
- kind cluster
- helm install
- build crossplane package
- apply crossplane package
- create providerconfig with aws credentials

```bash
CREDENTIALS=$(cat ~/.aws/credentials.txt) ./setup.sh
```
