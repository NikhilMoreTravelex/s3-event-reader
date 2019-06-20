
resource "aws_s3_bucket" "config" {
  bucket_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-config-"
  acl           = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.app_data.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-config"
    )
  )}"
}

resource "aws_s3_bucket_policy" "config_bucket" {
  bucket = "${aws_s3_bucket.config.id}"
  policy = "${data.template_file.config_bucket_policy.rendered}"
}

