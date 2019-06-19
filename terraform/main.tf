terraform {
  required_version = ">= 0.11.14"

  backend "s3" {
    region = "${var.region}"
  }
}

provider "aws" {
  region = "${var.region}"
}
