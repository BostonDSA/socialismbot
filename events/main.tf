locals {
  lambda_filename         = var.package
  lambda_source_code_hash = filebase64sha256(var.package)

  filter_policy = {
    callback_id = ["events", "events_post"]
    id          = ["dialog_submission", "interactive_message"]
    type        = ["callback"]
  }

  payload = {
    callback_id = "events_post"

    submission = {
      conversation = var.channel
    }
  }

  response = {
    attachments = [
      {
        callback_id = "events"
        color       = "#b71c1c"
        fallback    = "Chapter Events"
        mrkdwn_in   = ["text"]
        text        = "Post today's events to a conversation you are in.\nOr copy <https://facebook.com/BostonDSA|facebook> events to <https://calendar.google.com/calendar/r?cid=dTIxbThrdDhiYjFsZmxwOGpwbWQzMTdpaWtAZ3JvdXAuY2FsZW5kYXIuZ29vZ2xlLmNvbQ|Google Calendar> _(this auto-runs hourly)_."

        actions = [
          {
            name  = "post"
            text  = "Post events"
            type  = "button"
            value = "post"
          },
          {
            name  = "sync"
            text  = "Sync facebook"
            type  = "button"
            value = "sync"
          },
        ]
      },
      {
        color       = "#b71c1c"
        title       = "Subscribe to this Calendar!"
        fallback    = "Subscribe to this Calendar!"
        footer      = "<https://github.com/BostonDSA/socialismbot|BostonDSA/socialismbot>"
        footer_icon = "https://assets-cdn.github.com/favicon.ico"
        mrkdwn_in   = ["text"]
        text        = "_Have you ever missed a Boston DSA event because you didn't hear about it until it was too late? Subscribe to this calendar to receive push notifications about upcoming DSA events sent directly to your mobile device._"

        actions = [
          {
            type = "button"
            name = "subscribe"
            text = "Subscribe"
            url  = "https://calendars.dsausa.org/u21m8kt8bb1lflp8jpmd317iik%40group.calendar.google.com"
          },
        ]
      },
    ]
  }
}

data aws_kms_key key {
  key_id = "alias/aws/secretsmanager"
}

data aws_secretsmanager_secret google {
  name = "google/socialismbot"
}

data aws_iam_policy_document events {
  statement {
    sid       = "DecryptKmsKey"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_key.key.arn]
  }

  statement {
    sid       = "GetSecretValue"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.google.arn]
  }

  statement {
    sid       = "InvokeFunction"
    actions   = ["lambda:InvokeFunction"]
    resources = [data.aws_lambda_function.facebook_gcal_sync.arn]
  }
}

data aws_iam_role role {
  name = var.role_name
}

data aws_sns_topic slackbot {
  name = var.slackbot_topic
}

data aws_lambda_function facebook_gcal_sync {
  function_name = "facebook-gcal-sync"
}

module slash_command {
  source         = "amancevice/slackbot-slash-command/aws"
  version        = "~> 14.0"
  slash_command  = "events"
  api_name       = var.api_name
  kms_key_arn    = var.kms_key_arn
  lambda_tags    = var.tags
  log_group_tags = var.tags
  response       = jsonencode(local.response)
  role_name      = var.role_name
  secret_name    = var.secret_name
  slackbot_topic = data.aws_sns_topic.slackbot.name
}

resource aws_cloudwatch_event_rule callback_rule {
  description         = "Post daily events to Slack"
  name                = "slack-post-events"
  schedule_expression = "cron(0 16 * * ? *)"
}

resource aws_cloudwatch_event_target callback_target {
  rule  = aws_cloudwatch_event_rule.callback_rule.name
  arn   = aws_sns_topic.events.arn
  input = jsonencode(local.payload)
}

resource aws_cloudwatch_log_group callback_logs {
  name              = "/aws/lambda/${aws_lambda_function.callback.function_name}"
  retention_in_days = 30
  tags              = var.tags
}

resource aws_iam_role_policy events {
  name   = "events"
  policy = data.aws_iam_policy_document.events.json
  role   = data.aws_iam_role.role.id
}

resource aws_lambda_function callback {
  description      = "Publish Google Calendar events to Slack"
  filename         = local.lambda_filename
  function_name    = "slack-socialismbot-callback-events"
  handler          = "index.handler"
  memory_size      = 1024
  role             = data.aws_iam_role.role.arn
  runtime          = "nodejs12.x"
  source_code_hash = local.lambda_source_code_hash
  tags             = var.tags
  timeout          = 30

  environment {
    variables = {
      FACEBOOK_PAGE_ID            = "BostonDSA"
      FACEBOOK_SYNC_FUNCTION_NAME = data.aws_lambda_function.facebook_gcal_sync.function_name
      GOOGLE_CALENDAR_ID          = "u21m8kt8bb1lflp8jpmd317iik@group.calendar.google.com"
      GOOGLE_SECRET               = "google/socialismbot"
      HELP_URL                    = "https://github.com/BostonDSA/socialismbot/blob/master/slash/events/docs/help.md#help"
      SLACK_COLOR                 = "#b71c1c"
      SLACK_SECRET                = "slack/socialismbot"
      TZ                          = "America/New_York"
    }
  }
}

resource aws_lambda_permission events {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callback.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.events.arn
}

resource aws_lambda_permission events_callback {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callback.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.slackbot.arn
}

resource aws_sns_topic events {
  name = "slack-${var.api_name}-events"
}

resource aws_sns_topic_subscription events {
  endpoint  = aws_lambda_function.callback.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.events.arn
}

resource aws_sns_topic_subscription events_callback {
  endpoint      = aws_lambda_function.callback.arn
  protocol      = "lambda"
  topic_arn     = data.aws_sns_topic.slackbot.arn
  filter_policy = jsonencode(local.filter_policy)
}
