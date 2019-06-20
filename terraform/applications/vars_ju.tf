variable "organisation" {
  type = "string"
}

variable "owner" {
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
