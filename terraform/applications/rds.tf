#Below module will create db instance for rts services like cumulative and buyback applications

module "rts_db_ireland" {
  source                  = "git::github.com/travelex/it-infra-modules.git//terraform_modules/sub_modules/rds_mssql"
  multi_az                = "${local.rds_multi_az[local.app_env]}"
  app_env                 = "${local.app_env}"
  app_parent              = "${var.app_parent}"
  app_name                = "${var.app_name}"
  target_region           = "${var.target_region}"
  launch_az               = "${local.launch_az}"
  rds_vol_size            = "${local.rds_vol_size[local.app_env]}"
  rds_backup_retention    = "${local.rds_backup_retention[local.app_env]}"
  db_subnet_group_name    = "${element(module.network_ireland.private_db_subnet_group,0)}"
  rds_engine              = "${local.rds_engine[local.app_env]}"
  rds_engine_version      = "${local.rds_engine_version[local.app_env]}"
  rds_instance_type       = "${local.rds_instance_type[local.app_env]}"
  data_kms_arn            = "${aws_kms_key.app_data.arn}"
  license_model           = "${local.license_model}"
  rds_backup_window       = "${local.rds_backup_window[local.app_env]}"
  rds_maintenance_window  = "${local.rds_maintenance_window[local.app_env]}"
  rds_storage_type        = "${local.rds_storage_type[local.app_env]}"
  rds_vol_size            = "${local.rds_vol_size[local.app_env]}"
  rds_username            = "${local.rds_username}"
  rds_root_password       = "${random_string.rds_root_password.result}"
  rds_s3_bucket_name      = "${aws_s3_bucket.config.id}"
  rds_s3_bucket_prefix    = "${local.s3_prefix["rds"]}"
  vpc_common_tags         = "${module.network_ireland.vpc_common_tags}"
  vpc_id                  = "${module.network_ireland.vpc_id}"
  rds_option_group_engine = "${local.rds_option_group_engine[local.app_env]}"
}

resource "aws_db_event_subscription" "rds" {
  name      = "rds-event-sub"
  sns_topic = "${aws_sns_topic.rds.arn}"

  source_type = "db-instance"
  source_ids  = ["${module.rts_db_ireland.db_instance_id}"]

  event_categories = [
    "configuration change",
    "read replica",
    "failover",
    "failure",
    "notification",
    "creation",
    "availability",
    "low storage",
    "recovery",
    "maintenance",
    "backtrack",
    "deletion",
    "restoration",
    "backup"
  ]
}
