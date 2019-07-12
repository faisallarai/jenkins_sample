provider "aws" {
  region = var.region
}

data "aws_ami" "hubte_jenkins_ami" {
  most_recent = true
  owners = ["self"]

  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "state"
    values = ["available"]
  }

  filter {
    name = "tag:Name"
    values = ["Jenkins-Golden-Image"]
  }
}

resource "tls_private_key" "hubtel_jenkins_key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "hubtel_jenkins_key_pair" {
  key_name = var.key_name
  public_key = "${tls_private_key.hubtel_jenkins_key.public_key_openssh}"
}

resource "aws_security_group" "hubtel_jenkins_sg" {
  name = "hubtel_jenkins_sg"
  description = "Hubtel Jenkins SG"
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow 80 for all"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow 443 for all"
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["45.222.192.146/32"]
    description = "Allow 8080 for only hubtel users"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["45.222.192.146/32"]
    description = "Allow 22 for only hubtel users"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "instance" {
  ami = "${data.aws_ami.hubte_jenkins_ami.id}"
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  key_name = var.key_name # or use data to fetch key_name generated from packer
  security_groups = ["${aws_security_group.hubtel_jenkins_sg.id}"]

  tags = {
    Name = "Jenkins-Golden-Image"
    Environment = var.environment_tag
  }
}

resource "aws_eip" "ec2_eip" {
  instance = "${aws_instance.instance.id}"
  vpc = true
}
