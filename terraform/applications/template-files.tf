/*
data "template_file" "logs_bucket_policy" {
  template = "${file("${path.module}/templates/logs-bucket-policy.json")}"
    vars {
      log_bucket_name = "${aws_s3_bucket.logs.id}"
  }
}
*/



data "template_file" "config_bucket_policy" {
  template = "${file("${path.module}/templates/config-bucket-policy.json")}"

  vars {
    #account_id = "${data.aws_caller_identity.this.account_id}"
    #assumed_role_id = "${element(split(":",data.aws_caller_identity.this.user_id),0)}"
    #instance_role_id = "${aws_iam_role.instance_role.unique_id}"
    #rds_role_id = "${aws_iam_role.rds_role.unique_id}"
    bucket_name = "${aws_s3_bucket.config.id}"

    data_kms_arn = "${aws_kms_key.app_data.arn}"
  }
}

data "template_file" "instance_policy" {
  template = "${file("${path.module}/templates/instance-policy.json")}"

  vars {
    data_kms_arn         = "${aws_kms_key.app_data.arn}"
    config_bucket_name   = "${aws_s3_bucket.config.id}"
    account_id           = "${data.aws_caller_identity.this.account_id}"
    region               = "${var.target_region}"
    argos_password       = "${aws_ssm_parameter.rds_admin_password.name}"
  }
}

data "template_file" "saml_policy" {
  template = "${file("${path.module}/templates/assume-saml.json")}"

  vars {
    account_id          = "${data.aws_caller_identity.this.account_id}"
    region              = "${var.target_region}"
  }
}

data "template_file" "support_policy" {
  template = "${file("${path.module}/templates/support-policy.json")}"

  vars {
    account_id          = "${data.aws_caller_identity.this.account_id}"
    region              = "${var.target_region}"
  }
}

data "template_file" "data_kms_use_policy" {
  template = "${file("${path.module}/templates/data-kms-use-policy.json")}"

  vars {
    account_id       = "${data.aws_caller_identity.this.account_id}"
    assumed_role_id  = "${element(split(":",data.aws_caller_identity.this.user_id),0)}"
    assumed_role_arn = "${data.aws_caller_identity.this.arn}"
    instance_role_id = "${aws_iam_role.instance_role.unique_id}"
  }
}


