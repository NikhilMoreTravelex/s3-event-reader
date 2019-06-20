resource "aws_s3_bucket" "middleware" {
  bucket = "${organisation}-${local.name_prefix}-middleware"
  acl    = "private"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${organisation}-${local.name_prefix}-middleware",
    )
  )}"

  lifecycle {
    prevent_destroy = "${var.middleware_bucket_prevent_destroy}"
  }
}

resource "aws_s3_bucket" "lambda_source" {
  bucket = "${organisation}-${local.name_prefix}-lambda-source"
  acl    = "private"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${organisation}-${local.name_prefix}-lambda-source",
    )
  )}"
}
