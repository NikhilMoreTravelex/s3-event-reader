resource "aws_sns_topic" "rds" {
  name = "rds-events"
}

# terraform doesn't support the e-mail SNS subscription!
resource "aws_cloudformation_stack" "rds_sns_stack" {
  count = "${length(local.infra_support_email)}"

  name          = "${local.app_env}-${var.app_parent}-${var.app_name}-rds-subscription-${count.index}"
  template_body = "${file("${path.module}/templates/sns-stack.yml")}"

  parameters {
    TopicArn     = "${aws_sns_topic.rds.arn}"
    EMailAddress = "${local.infra_support_email[count.index]}"
  }

  tags = "${local.common_tags}"
}
