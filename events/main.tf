locals {
  callback_ids = [
    "events",
    "events_post",
  ]

  payload {
    callback_id = "events_post"
    submission {
      conversation = "${var.channel_events}"
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
    resources = ["${data.aws_kms_key.key.arn}"]
  }

  statement {
    sid       = "GetSecretValue"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["${data.aws_secretsmanager_secret.google.arn}"]
  }

  statement {
    sid       = "InvokeFunction"
    actions   = ["lambda:InvokeFunction"]
    resources = ["${data.terraform_remote_state.facebook_gcal_sync.lambda_function_arn}"]
  }
}

data aws_iam_role role {
  name = "${var.role_name}"
}

data terraform_remote_state facebook_gcal_sync {
  backend = "s3"
  config {
    bucket  = "terraform.bostondsa.org"
    key     = "facebook-gcal-sync.tfstate"
    region  = "us-east-1"
    profile = "bdsa"
  }
}

module slash_command {
  source        = "amancevice/slackbot-slash-command/aws"
  version       = "9.0.0"
  api_name      = "${var.api_name}"
  kms_key_arn   = "${var.kms_key_arn}"
  role_name     = "${var.role_name}"
  secret_name   = "${var.secret_name}"
  slash_command = "events"

  response {
    attachments = [
      {
        callback_id = "events"
        color       = "#b71c1c"
        fallback    = "Chapter Events"
        mrkdwn_in   = ["text"]
        text        = "Post today's events to a conversation you are in.\nOr copy <https://facebook.com/BostonDSA|facebook> events to <https://calendar.google.com/calendar/r?cid=dTIxbThrdDhiYjFsZmxwOGpwbWQzMTdpaWtAZ3JvdXAuY2FsZW5kYXIuZ29vZ2xlLmNvbQ|Google Calendar> _(this auto-runs hourly)_."
        actions     = [
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
          }
        ]
      },
      {
        color       = "#b71c1c"
        title       = "Subscribe to this Calendar!"
        fallback    = "Subscribe to this Calendar!"
        footer      = "<https://github.com/BostonDSA/socialismbot|BostonDSA/socialismbot>"
        footer_icon = "https://assets-cdn.github.com/favicon.ico"
        mrkdwn_in   = ["text"]
        text        = "_Have you ever missed a Boston DSA event because you didn't hear about it until it was too late? Subscribe to this calendar to receive push notifications about upcoming DSA events sent directly to your mobile device._",
        actions     = [
          {
            type = "button",
            name = "subscribe",
            text = "Subscribe",
            url  = "https://calendars.dsausa.org/u21m8kt8bb1lflp8jpmd317iik%40group.calendar.google.com"
          }
        ]
      }
    ]
  }
}

resource aws_cloudwatch_event_rule callback_rule {
  description         = "Post daily events to Slack"
  name                = "slack-post-events"
  schedule_expression = "cron(0 16 * * ? *)"
}

resource aws_cloudwatch_event_target callback_target {
  rule  = "${aws_cloudwatch_event_rule.callback_rule.name}"
  arn   = "${aws_lambda_function.callback.arn}"
  input = "${jsonencode("${local.message}")}"
}

resource aws_cloudwatch_log_group callback_logs {
  name              = "/aws/lambda/${aws_lambda_function.callback.function_name}"
  retention_in_days = 30
}

resource aws_iam_role_policy events {
  name   = "events"
  policy = "${data.aws_iam_policy_document.events.json}"
  role   = "${data.aws_iam_role.role.id}"
}

resource aws_lambda_function callback {
  description      = "Publish Google Calendar events to Slack"
  filename         = "${path.module}/package.zip"
  function_name    = "slack-socialismbot-callback-events"
  handler          = "index.handler"
  memory_size      = 1024
  role             = "${data.aws_iam_role.role.arn}"
  runtime          = "nodejs8.10"
  source_code_hash = "${base64sha256(file("${path.module}/package.zip"))}"
  timeout          = 3

  environment {
    variables {
      FACEBOOK_PAGE_ID            = "BostonDSA"
      FACEBOOK_SYNC_FUNCTION_NAME = "${data.terraform_remote_state.facebook_gcal_sync.lambda_function_name}"
      GOOGLE_CALENDAR_ID          = "u21m8kt8bb1lflp8jpmd317iik@group.calendar.google.com"
      GOOGLE_SECRET               = "google/socialismbot"
      HELP_URL                    = "https://github.com/BostonDSA/socialismbot/blob/master/slash/events/docs/help.md#help"
      SLACK_COLOR                 = "#b71c1c"
      SLACK_SECRET                = "slack/socialismbot"
      STATE_MACHINE_ARN           = "arn:aws:states:us-east-1:715992480927:stateMachine:facebook-gcal-sync"
      TZ                          = "America/New_York"
    }
  }
}

resource aws_lambda_permission callback_events {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.callback.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.callback_rule.arn}"
}

resource aws_lambda_permission callback_sns {
  count         = "${length(local.callback_ids)}"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.callback.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${element(aws_sns_topic.callback_topics.*.arn, count.index)}"
}

resource aws_sns_topic callback_topics {
  count = "${length(local.callback_ids)}"
  name  = "slack_${var.api_name}_callback_${element(local.callback_ids, count.index)}"
}

resource aws_sns_topic_subscription callback_subscriptions {
  count     = "${length(local.callback_ids)}"
  endpoint  = "${aws_lambda_function.callback.arn}"
  protocol  = "lambda"
  topic_arn = "${element(aws_sns_topic.callback_topics.*.arn, count.index)}"
}
