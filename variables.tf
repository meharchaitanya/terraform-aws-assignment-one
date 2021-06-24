variable "aws_access_key" {
    default = "add your access key"
}
variable "aws_secret_key" {
   default = "add your secret key"
}


variable "region" {
    default = "ap-south-1"
  }
variable "dev_cidr_block" {
default = "192.168.0.0/16"
}

variable "dev_private_az" {
default = "ap-south-1a"
}

variable  "dev_public_subnet_cidr_block" {
  default = "192.168.0.0/24"
}

variable "dev_public_az" {
default = "ap-south-1a"
}

variable "dev_rds_az_1" {
default = "ap-south-1a"
}

variable "dev_rds_az_2" {
default = "ap-south-1b"
}


variable "dev_private_backend_subnet_cidr_block" {
default ="192.168.1.0/24"
}

variable "dev_private_rds_subnet_cidr_block_1" {
	default ="192.168.2.0/24"
}

variable "dev_private_rds_subnet_cidr_block_2" {
	default ="192.168.3.0/24"
}

variable "Dev_frontend_ami" {
default = "ami-06a0b4e3b7eb7a300"
}