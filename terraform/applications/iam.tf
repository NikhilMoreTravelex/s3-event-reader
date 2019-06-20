# Common Services EC2 Instance/Server IAM role

resource "aws_iam_role" "instance_role" {
  name_prefix        = "${local.app_env}-${var.app_parent}-${var.app_name}-"
  assume_role_policy = "${file("${path.module}/templates/assume-ec2.json")}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-ec2_role"
    )
  )}"
}

resource "aws_iam_role" "support_role" {
  name               = "ADFS-${var.aws_account_name}-SupportAccess"
  assume_role_policy = "${data.template_file.saml_policy.rendered}"
  max_session_duration = "10800"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-support-role"
    )
  )}"
}

# Common Services EC2 Instance/Server IAM role policy to access s3 config bucket, ssm.
resource "aws_iam_role_policy" "instance_policy" {
  name_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-policy-"
  role        = "${aws_iam_role.instance_role.id}"
  policy      = "${data.template_file.instance_policy.rendered}"
}

# Common Services EC2 Instance/Server IAM role policy to set it as managed SSM instance.
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = "${aws_iam_role.instance_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# Policy for support access.
resource "aws_iam_role_policy" "support_policy" {
  name_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-support-policy-"
  role        = "${aws_iam_role.support_role.id}"
  policy      = "${data.template_file.support_policy.rendered}"
}
