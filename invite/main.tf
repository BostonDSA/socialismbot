locals {
  lambda_filename         = var.package
  lambda_source_code_hash = filebase64sha256(var.package)

  filter_policy = {
    id   = ["invite"]
    type = ["callback"]
  }
}

data aws_iam_role role {
  name = var.role_name
}

data aws_sns_topic slackbot {
  name = var.slackbot_topic
}

resource aws_cloudwatch_log_group callback_logs {
  name              = "/aws/lambda/${aws_lambda_function.callback.function_name}"
  retention_in_days = 30
}

resource aws_lambda_function callback {
  description      = "Slack invitater"
  filename         = local.lambda_filename
  function_name    = "slack-${var.api_name}-callback-invite"
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
      SLACK_SECRET = var.secret_name
    }
  }
}

resource aws_lambda_permission callback {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callback.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.slackbot.arn
}

resource aws_sns_topic_subscription callback {
  endpoint      = aws_lambda_function.callback.arn
  protocol      = "lambda"
  topic_arn     = data.aws_sns_topic.slackbot.arn
  filter_policy = jsonencode(local.filter_policy)
}
