variable "region" {
  default = "eu-west-1"
}
variable "vpc_id" {
  description = "VPC id"
  default = "vpc-0aba3864c4f833a84"
}
variable "subnet_id" {
  description = "VPC subnet id"
  default = "subnet-0c9cf78e99d289246"
}
variable "environment_tag" {
  description = "Environment tag"
  default = "Staging"
}
variable "key_name" {
  description = "EC2 key pair name"
  default = "hubtel_jenkins_key"
}
variable "instance_type" {
  description = "EC2 instance type"
  default = "t2.micro"
}
variable "security_group_ids" {
  description = "EC2 security group ids"
  default = ""
}
