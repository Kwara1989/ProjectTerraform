provider "aws" {
    region = "${var.aws_region}"
}


resource "aws_cloudwatch_event_rule" "check-file-event" {
    name = "check-file-event"
    description = "check-file-event"
    schedule_expression = "cron(0 1 ? * * *)"
}


resource "aws_cloudwatch_event_target" "check-file-event-lambda-target" {
    target_id = "check-file-event-lambda-target"
    rule = "${aws_cloudwatch_event_rule.check-file-event.name}"
    arn = "${aws_lambda_function.check_file_lambda.arn}"
}



resource "aws_iam_role" "check_file_lambda" {
    name = "check_file_lambda"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}




data "aws_iam_policy_document" "s3-access-ro" {
    statement {
        actions = [
            "s3:*",
        ]
        resources = [
            "arn:aws:s3:::*",
        ]
    }
}

resource "aws_iam_policy" "s3-access-ro" {
    name = "s3-access-ro"
    path = "/"
    policy = "${data.aws_iam_policy_document.s3-access-ro.json}"
}

resource "aws_iam_role_policy_attachment" "s3-access-ro" {
    role       = "${aws_iam_role.check_file_lambda.name}"
    policy_arn = "${aws_iam_policy.s3-access-ro.arn}"
}









resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_file" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.check_file_lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.check-file-event.arn}"
}


resource "aws_lambda_function" "check_file_lambda" {
    filename = "check_file_lambda.zip"
    function_name = "check_file_lambda"
    role = "${aws_iam_role.check_file_lambda.arn}"
    handler = "check_file_lambda.handler"
    runtime = "python3.6"
    timeout = 300
    source_code_hash = "${filebase64sha256("check_file_lambda.zip")}"
}
