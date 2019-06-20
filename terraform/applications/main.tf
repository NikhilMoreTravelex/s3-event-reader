provider "aws" {
  # Default
  #alias = "ireland"
  region = "eu-west-1"
}


terraform {
  backend "s3" {}
}

data "aws_caller_identity" "this" {}

data "aws_availability_zones" "available" {}

data "aws_ami" "windows" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "Windows_Server-2016-English-Full-Base*",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"] # Microsoft
}

