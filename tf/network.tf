resource "aws_vpc" "test-env" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
}

resource "aws_subnet" "subnet" {
    cidr_block = "10.0.0.0/24"
    vpc_id = "${aws_vpc.test-env.id}"
    availability_zone = "us-east-1a"
}

resource "aws_security_group" "ingress-all-test" {
    name = "allow-all-sg"
    vpc_id = "${aws_vpc.test-env.id}"
    ingress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        from_port = 22
        to_port = 22
        protocol = "tcp"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_internet_gateway" "test-env-gw" {
    vpc_id = "${aws_vpc.test-env.id}"
}

resource "aws_route_table" "route-table-test-env" {
    vpc_id = "${aws_vpc.test-env.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.test-env-gw.id}"
    }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.route-table-test-env.id}"
}