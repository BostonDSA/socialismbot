locals {
  callback_id = "events_post"
  rule_arn    = "${aws_cloudwatch_event_rule.noon_edt.arn}"
  rule_name   = "${aws_cloudwatch_event_rule.noon_edt.name}"

  events  = "C7F7Z0WJG"
  testing = "GB1SLKKL7"

  payload {
    submission {
      conversation = "${local.events}"
    }
  }

  message {
    Records = [
      {
        Sns {
          Message = "${base64encode("${jsonencode("${local.payload}")}")}"
        }
      }
    ]
  }
}

data aws_iam_role role {
  name = "${var.role_name}"
}

module events {
  source        = "amancevice/slackbot-slash-command/aws"
  version       = "8.0.0"
  api_name      = "${var.api_name}"
  kms_key_arn   = "${var.kms_key_arn}"
  role_name     = "${var.role_name}"
  secret_name   = "${var.secret_name}"
  slash_command = "events"

  response {
    response_type = "dialog"
    callback_id   = "${local.callback_id}"
    title         = "Post Today's Events"
    submit_label  = "Post"
    elements      = [
      {
        data_source = "conversations"
        hint        = "Choose a conversation for events"
        label       = "Conversation"
        name        = "conversation"
        type        = "select"
      }
    ]
  }
}

resource aws_cloudwatch_event_rule noon_edt {
  description         = "Every day at 12pm Eastern Daylight Time"
  name                = "every-day-at-12pm-edt"
  schedule_expression = "cron(0 16 * * ? *)"
}

resource aws_cloudwatch_event_rule noon_est {
  description         = "Every day at 12pm Eastern Standard Time"
  name                = "every-day-at-12pm-est"
  schedule_expression = "cron(0 17 * * ? *)"
}

resource aws_cloudwatch_event_target target {
  rule  = "${local.rule_name}"
  arn   = "${aws_lambda_function.lambda.arn}"
  input = "${jsonencode("${local.message}")}"
}

resource aws_cloudwatch_log_group logs {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 30
}

resource aws_lambda_function lambda {
  description      = "Publish Google Calendar events to Slack"
  filename         = "${path.module}/package.zip"
  function_name    = "slack-${var.api_name}-post-events"
  handler          = "index.handler"
  memory_size      = 1024
  role             = "${data.aws_iam_role.role.arn}"
  runtime          = "nodejs8.10"
  source_code_hash = "${base64sha256(file("${path.module}/package.zip"))}"
  timeout          = 3

  environment {
    variables {
      AWS_SECRET         = "google/${var.api_name}"
      COLOR              = "#b71c1c"
      GOOGLE_CALENDAR_ID = "${var.google_calendar_id}"
      HELP_URL           = "https://github.com/BostonDSA/socialismbot/blob/master/slash/events/docs/help.md#help"
      TOPIC_ARN          = "${var.topic_arn}"
    }
  }
}

resource aws_lambda_permission cloudwatch {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${local.rule_arn}"
  statement_id  = "AllowExecutionFromCloudwatch"
}

resource aws_lambda_permission trigger {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.topic.arn}"
  statement_id  = "AllowExecutionFromSNS"
}

resource aws_sns_topic topic {
  name = "slack_${var.api_name}_callback_${local.callback_id}"
}

resource aws_sns_topic_subscription subscription {
  endpoint  = "${aws_lambda_function.lambda.arn}"
  protocol  = "lambda"
  topic_arn = "${aws_sns_topic.topic.arn}"
}
