locals {
  callback_ids = [
    "report_message_action",
    "report_message_submit",
  ]
}

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
  tags              = "${var.tags}"
}

resource aws_lambda_function callback {
  description      = "Slackbot moderator helper"
  filename         = "${data.archive_file.package.output_path}"
  function_name    = "slack-${var.api_name}-callback-mods"
  kms_key_arn      = "${var.kms_key_arn}"
  handler          = "index.handler"
  memory_size      = 1024
  role             = "${data.aws_iam_role.role.arn}"
  runtime          = "nodejs8.10"
  source_code_hash = "${data.archive_file.package.output_base64sha256}"
  tags             = "${var.tags}"
  timeout          = 10

  environment {
    variables {
      MOD_CHANNEL  = "${var.channel}"
      SLACK_SECRET = "${var.secret_name}"
    }
  }
}

resource aws_lambda_permission trigger {
  count         = "${length("${local.callback_ids}")}"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.callback.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${element("${aws_sns_topic.callbacks.*.arn}", count.index)}"
}

resource aws_sns_topic callbacks {
  count = "${length("${local.callback_ids}")}"
  name  = "slack_${var.api_name}_callback_${element("${local.callback_ids}", count.index)}"
}

resource aws_sns_topic_subscription subscription {
  count     = "${length("${local.callback_ids}")}"
  endpoint  = "${aws_lambda_function.callback.arn}"
  protocol  = "lambda"
  topic_arn = "${element("${aws_sns_topic.callbacks.*.arn}", count.index)}"
}
