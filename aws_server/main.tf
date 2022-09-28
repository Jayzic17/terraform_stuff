# This is a sub-Module we made to be used in the main.tf file

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "3.58.0"
        }
    }
}

provider "aws" {
    profile = "default"
    region = "us-east-1"
}

resource "aws_instance" "my_server" {
    ami = "ami-087c17d1f30178315"     
    instance_type = var.instance_type 
}

variable "instance_type" {
    type = string
    validation {
        condition = can(regex("^t2.-", var.instance_type))
        error_message = "The instance type value must be a valid instance type."
    }
}