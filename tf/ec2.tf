resource "aws_instance" "ec2-instance" {
    ami = "${var.ami_id}"
    instance_type = "t3.micro"
    key_name = "${var.key_pair_name}"
    security_groups = ["${aws_security_group.ingress-all-test.id}"]
    subnet_id = "${aws_subnet.subnet.id}"
}

resource "aws_eip" "ip-test-env" {
  instance = "${aws_instance.ec2-instance.id}"
}
