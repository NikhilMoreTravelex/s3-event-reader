resource "aws_kms_key" "app_data" {
  description         = "${local.app_env}-${var.app_parent}-${var.app_name}-data-key"
  enable_key_rotation = true
  policy              = "${data.template_file.data_kms_use_policy.rendered}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-data-key"
    )
  )}"
}

resource "aws_kms_alias" "app_data_alias" {
  name_prefix   = "alias/${local.app_env}-${var.app_parent}-${var.app_name}-data-key-"
  target_key_id = "${aws_kms_key.app_data.key_id}"
}
