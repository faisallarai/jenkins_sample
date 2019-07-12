provider "aws" {
  region = var.region
}

data "aws_ami" "hubte_apps_ami" {
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
    values = ["${var.tag_name}"]
  }
}

resource "tls_private_key" "hubtel_apps_key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "hubtel_apps_key_pair" {
  key_name = "${var.job_name}-key"
  public_key = "${tls_private_key.hubtel_apps_key.public_key_openssh}"
}

resource "aws_security_group" "hubtel_apps_sg" {
  name = "${var.job_name}_sg"
  description = "SG"
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
    from_port = 9052
    to_port = 9052
    protocol = "tcp"
    cidr_blocks = ["45.222.192.146/32"]
    description = "Allow 9052 for only hubtel users"
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
  ami = "${data.aws_ami.hubte_apps_ami.id}"
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  key_name = "intern-group" # "${var.job_name}-key" or use data to fetch key_name generated from packer
  security_groups = ["${aws_security_group.hubtel_apps_sg.id}"]

  tags = {
    Name = var.job_name
    BUILD = var.tag_name
    Environment = var.environment_tag
  }
}

resource "aws_eip" "ec2_eip" {
  instance = "${aws_instance.instance.id}"
  vpc = true
}
