variable "organisation" {
  type = "string"
}

variable "cost_code" {
  type = "string"
}

variable "owner" {
  type = "string"
}

variable "environment" {
  type = "string"
}

variable "application" {
  type = "string"
}

variable "account" {
  type = "string"
}

variable "region" {
  type = "string"
}

locals {
  name_prefix = "${var.application}-${var.environment}"

  common_tags = {
    Application = "${var.application}"
    CostCode    = "${var.cost_code}"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
  }
}

variable "lambda_memory_size" {
  type = "string"
}

variable "lambda_timeout" {
  type = "string"
}

variable "lambda_version" {
  type = "string"
}

variable "lambda_package_filename" {
  type = "string"
  default = "lambda.zip"
}

variable "middleware_bucket_prevent_destroy" {
  type = "string"
}
