locals {
  app_name = "rds-ip-update-in-targetgroup"

  # Module name (file name) of python code to be used as lambda file.
  lambda_name = "argosfx-rds"

  # Handler name (function name) of python code to execute as entry point.
  create_aws_account_lambda_handler = "lambda_handler"

  # Lambda python runtime code to execute code.
  create_aws_account_lambda_runtime= "python3.6"

  # Lambda python timeout in seconds for code execution.
  create_aws_account_lambda_timeout = 300
  create_aws_account_tags = {
    Name = "${var.app_name}"
  }

}

data "template_file" "lambda_execution_policy" {
  template = "${file("${path.module}/templates/rds-lambda-exec-policy.json")}"
      vars {
        rds-arn = "${module.rts_db_ireland.rds_role_arn}"
    }  
}


data "template_file" "assume_lambda" {
  template = "${file("templates/assume-lambda.json")}"
}


# Create IAM role to apply to lambda as an execution role.
resource "aws_iam_role" "lambda_execution" {
  name_prefix = "${var.app_name}-lmbda"
  assume_role_policy = "${data.template_file.assume_lambda.rendered}"
}

# Create IAM policy to apply to lambda execution role.
resource "aws_iam_role_policy" "lambda_execution" {
  name_prefix = "${local.app_name}-lambda-execution-"
  role = "${aws_iam_role.lambda_execution.id}"
  policy = "${data.template_file.lambda_execution_policy.rendered}"
}

# Create Lambda function to create aws member account.
resource "aws_lambda_function" "sc_create_aws_account" {
  function_name = "${local.app_name}-rds"
  filename = "lambda/${local.lambda_name}.zip"
  source_code_hash = "${base64sha256(file("lambda/argosfx-rds.zip"))}"
  role          = "${aws_iam_role.lambda_execution.arn}"
  handler       = "${local.lambda_name}.${local.create_aws_account_lambda_handler}"
  runtime       = "${local.create_aws_account_lambda_runtime}"
  timeout       = "${local.create_aws_account_lambda_timeout}"
  description   = "Create AWS Lambda Function for changing the targate group ip if rds ip is changed"
  tags = "${merge(
  local.common_tags,
  map(
    "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-server"
  )
  )}"
  environment {
    variables {
      DB_INSTANCE       = "${module.rts_db_ireland.db_instance_id}"
      TARGETGROUP_ARN   = "${aws_lb_target_group.rds.arn}"
    }
  }
}

resource "aws_sns_topic" "rds-lambda" {
  name = "rds-lambda-events"
}

#used to create trigger for lambda
resource "aws_sns_topic_subscription" "rds-lambda-update-ip" {
  topic_arn = "${aws_sns_topic.rds-lambda.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.sc_create_aws_account.arn}"
}

resource "aws_cloudwatch_metric_alarm" "rds-ip-elb-unhealthy" {
  alarm_name                = "ec2-health-check"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "UnHealthyHostCount"
  namespace                 = "AWS/NetworkELB"
  dimensions = {
    TargetGroup  = "targetgroup/uat-ws-argosfx-rds/3e2eb3ab67972fe5"
    LoadBalancer = "net/uat-ws-argosfx-rds/56c220e27a07df03"
  }
  period                    = "120"
  statistic                 = "Maximum"
  threshold                 = "1"
  alarm_description         = "This metric monitors healthy status of target group"
  alarm_actions             = ["${aws_sns_topic.rds-lambda.arn}"]
 #arn:aws:sns:eu-west-1:012440728499:rds-lambda-events
  insufficient_data_actions = []
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-alarm"
    )
  )}"
}

#required to create triger for lambda
resource "aws_lambda_permission" "lambda_with_sns" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.sc_create_aws_account.arn}"
    principal = "sns.amazonaws.com"
    source_arn = "${aws_sns_topic.rds-lambda.arn}"
}

