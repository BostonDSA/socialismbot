locals {
  lambda_filename         = var.package
  lambda_source_code_hash = filebase64sha256(var.package)
  slackbot_topic          = var.slackbot_topic


  filter_policy = {
    callback_id = ["report_message_action", "report_message_submit"]
    id          = ["dialog_submission", "interactive_message", "message_action"]
    type        = ["callback"]
  }
}

data "aws_iam_role" "role" {
  name = var.role_name
}

data "aws_sns_topic" "slackbot" {
  name = local.slackbot_topic
}

resource "aws_cloudwatch_log_group" "callback_logs" {
  name              = "/aws/lambda/${aws_lambda_function.callback.function_name}"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_lambda_function" "callback" {
  description      = "Slackbot moderator helper"
  filename         = local.lambda_filename
  function_name    = "slack-${var.api_name}-callback-mods"
  kms_key_arn      = var.kms_key_arn
  handler          = "index.handler"
  memory_size      = 1024
  role             = data.aws_iam_role.role.arn
  runtime          = "nodejs12.x"
  source_code_hash = local.lambda_source_code_hash
  tags             = var.tags
  timeout          = 10

  environment {
    variables = {
      MOD_CHANNEL  = var.channel
      SLACK_SECRET = var.secret_name
    }
  }
}

resource "aws_lambda_permission" "trigger" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callback.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.slackbot.arn
}

resource "aws_sns_topic_subscription" "subscription" {
  endpoint      = aws_lambda_function.callback.arn
  protocol      = "lambda"
  topic_arn     = data.aws_sns_topic.slackbot.arn
  filter_policy = jsonencode(local.filter_policy)
}
