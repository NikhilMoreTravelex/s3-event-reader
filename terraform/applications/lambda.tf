resource "aws_lambda_function" "event_reader" {
  function_name = "${local.name_prefix}"
  handler       = "process-s3EventReader-handler.handle"
  description   = "Reads and is triggered by writes to S3 middleware bucket"
  role          = "${aws_iam_role.event_reader.arn}"
  s3_bucket     = "${aws_s3_bucket.lambda_source.id}"
  s3_key        = "${aws_s3_bucket_object.lambda_package.id}"
  runtime       = "nodejs8.10"
  memory_size   = 512
  timeout       = 60

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.name_prefix}",
    )
  )}"
}

resource "aws_lambda_permission" "event_reader_allow_s3" {
  statement_id  = "AllowExecutionFromMiddlewareBucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.event_reader.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.middleware.arn}"
}

resource "aws_s3_bucket_notification" "middleware_bucket_notification" {
  bucket = "${aws_s3_bucket.middleware.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.event_reader.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
  }
}

resource "random_string" "lambda_version" {
  length = 16
  special = false
}

resource "aws_s3_bucket_object" "lambda_package" {
  bucket = "${aws_s3_bucket.lambda_source.id}"
  key    = "${random_string.lambda_version.result}/${var.lambda_package_filename}"
  source = "/root/serverless/.serverless/s3-event-reader.zip"
  etag   = "${md5(file("/root/serverless/.serverless/s3-event-reader.zip"))}"
}
