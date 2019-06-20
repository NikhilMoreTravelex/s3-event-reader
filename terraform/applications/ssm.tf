resource "aws_ssm_parameter" "jump_host_common_private_key" {
  name        = "/${local.app_env}/${var.app_parent}/${var.app_name}/ec2/jumphost/privatekey"
  type        = "SecureString"
  value       = "${tls_private_key.jump_host_common.private_key_pem}"
  description = "${local.app_env} ${var.app_parent} ${var.app_name} jumphost ec2 instance private key"
  key_id      = "${aws_kms_key.app_data.arn}"
  overwrite   = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-jumphost-ssm-ec2-privatekey"
    )
  )}"
}

resource "aws_ssm_parameter" "server_private_key" {
  name        = "/${local.app_env}/${var.app_parent}/${var.app_name}/ec2/server/privatekey"
  type        = "SecureString"
  value       = "${tls_private_key.server.private_key_pem}"
  description = "${local.app_env} ${var.app_parent} ${var.app_name} application ec2 instance private key"
  key_id      = "${aws_kms_key.app_data.arn}"
  overwrite   = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-app-ssm-ec2-privatekey"
    )
  )}"
}



# generate a root password for rds database
resource "random_string" "rds_root_password" {
  length      = 24
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

resource "aws_ssm_parameter" "rds_admin_password" {
  name        = "/${local.app_env}/${var.app_parent}/${local.common_tags["Application"]}/rds/password"
  type        = "SecureString"
  value       = "${random_string.rds_root_password.result}"
  description = "${local.app_env}-${var.app_parent}-${local.common_tags["Application"]} rds admin password"
  key_id      = "${aws_kms_key.app_data.arn}"
  overwrite   = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${local.common_tags["Application"]}-ssm-rds-admin"
    )
  )}"
}

# generaate ARGOSAppAdmin DB password
resource "random_string" "argos_db_password" {
  length      = 24
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

resource "aws_ssm_parameter" "argos_db_password" {
  name        = "/${local.app_env}/${var.app_parent}/${local.common_tags["Application"]}/argosappadmin/password"
  type        = "SecureString"
  value       = "${random_string.argos_db_password.result}"
  description = "${local.app_env}-${var.app_parent}-${local.common_tags["Application"]} argos application admin password"
  key_id      = "${aws_kms_key.app_data.arn}"
  overwrite   = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${local.common_tags["Application"]}-ssm-argosapp-admin"
    )
  )}"
}

