resource "aws_s3_bucket" "middleware" {
  bucket = "${var.organisation}-${local.name_prefix}-middleware"
  acl    = "private"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.organisation}-${local.name_prefix}-middleware",
    )
  )}"
}

resource "aws_s3_bucket" "lambda_source" {
  bucket = "${var.organisation}-${local.name_prefix}-lambda-source"
  acl    = "private"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.organisation}-${local.name_prefix}-lambda-source",
    )
  )}"
}
