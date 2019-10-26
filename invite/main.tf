data archive_file package {
  type        = "zip"
  source_dir  = "${path.module}/"
  output_path = "${path.module}/package.zip"
}

data aws_iam_role role {
  name = "${var.role_name}"
}

resource aws_cloudwatch_log_group callback_logs {
  name              = "/aws/lambda/${aws_lambda_function.callback.function_name}"
  retention_in_days = 30
}

resource aws_lambda_function callback {
  description      = "Slack invitater"
  filename         = "${data.archive_file.package.output_path}"
  function_name    = "slack-${var.api_name}-callback-invite"
  kms_key_arn      = "${var.kms_key_arn}"
  handler          = "index.handler"
  memory_size      = 1024
  role             = "${data.aws_iam_role.role.arn}"
  runtime          = "nodejs10.x"
  source_code_hash = "${data.archive_file.package.output_base64sha256}"
  tags             = "${var.tags}"
  timeout          = 10

  environment {
    variables = {
      SLACK_SECRET = "${var.secret_name}"
    }
  }
}

resource aws_lambda_permission callback {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.callback.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.callback.arn}"
}

resource aws_sns_topic callback {
  name = "slack_${var.api_name}_callback_invite"
}

resource aws_sns_topic_subscription callback {
  endpoint  = "${aws_lambda_function.callback.arn}"
  protocol  = "lambda"
  topic_arn = "${aws_sns_topic.callback.arn}"
}
