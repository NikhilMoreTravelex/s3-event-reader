data "aws_iam_policy_document" "event_reader_assume_role" {
  statement {
    sid = "1"

    actions = ["sts:AssumeRole"]

    principals = {
      type = "Service"
      idenitifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "event_reader" {
  name = "${local.name_prefix}"
  assume_role_policy = "${data.aws_iam_policy_document.event_reader_assume_role.json}"
}
resource "aws_iam_role_policy" "event_reader_policy" {
  name = "${local.name_prefix}"
  role = "${aws_iam_role.event_reader.name}"
  policy = "${data.aws_iam_policy_document.event_reader_policy.json}"
}

data "aws_iam_policy_document" "event_reader_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:Get*",
      "s3:List*"
    ]

    resources = [
      "${aws_s3_bucket.middleware.arn}",
      "${aws_s3_bucket.middleware.arn}/*",
    ]
  }
}
