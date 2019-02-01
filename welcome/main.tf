locals {
  ask_sc            = "C9Z3M55DG"
  generaldiscussion = "C7M1CCBAQ"
  slack_meta        = "C7F6BQBEW"
  socialismbot      = "UAJGYQCQ1"
  testing           = "GB1SLKKL7"

  welcome {
    actions = [
      {
        text = "Learn More"
        type = "button"
        url  = "https://drive.google.com/file/d/0B6OdCRb_vSGzeTV4akFSRHF0NWs/view"
      }
    ]
    color     = "#f0433a"
    pretext   = ":sparkles: *Welcome to Boston DSA!* :sparkles:"
    mrkdwn_in = ["pretext", "text"]
    text      = "Take a moment to review the <https://www.dsausa.org/respectful_discussion|DSA Guidelines for Respectful Discussion>.\nMembers should adhere to the <https://bit.ly/BDSACode|Boston DSA Code of Conduct> at all times."
  }

  guidelines {
    actions   = [
      {
        text = "Learn More"
        type = "button"
        url  = "https://get.slack.help/hc/en-us/articles/115000769927-Message-and-file-threads"
      }
    ]
    color     = "#C9283E"
    fields    = [
      {
        title = "Ask Questions!"
        value = "Feel free to ask a question any time in any channel. _We are all here to help each other!_ The <#${local.ask_sc}> or <#${local.slack_meta}> channels are a great place to start."
      },
      {
        title = "Limits"
        value = "Please limit your contributions to a *single post at a time*. If you need to say more consider _editing_ your original message instead of posting a new one.\nThis helps members participate in an organized manner."
      },
      {
        title = "Threads"
        value = "If you'd like to get involved in a conversation please *join or start a thread* to avoid derailing other conversations by posting directly in the channel."
      }
    ],
    mrkdwn_in = ["fields", "pretext"]
    pretext   = ":mega: *Discussion Guidelines*"
  }

  channels {
    actions   = [
      {
        text = "Learn More"
        type = "button"
        url  = "https://get.slack.help/hc/en-us/articles/218080037-Getting-started-for-new-members"
      }
    ]
    color     = "#820333"
    fields    = [
      {
        title = "Public Channels"
        value = "Slack channels are like chat rooms; there are channels for working groups, committees, teams, caucuses and more! Click the word _Channels_ on the left panel to view all channels available to join."
      },
      {
        title = "Private Channels"
        value = "Special spaces for underprivileged groups exist but are _invitation only_. To request to join simply ask! Post in any channel and someone will help you get involved."
      }
    ]
    mrkdwn_in = ["fields", "pretext"]
    pretext   = "*:tv: Slack Channels*"
  }

  bot {
    color       =  "#540032"
    footer      =  "<https://github.com/BostonDSA/socialismbot|BostonDSA/socialismbot>"
    footer_icon =  "https://assets-cdn.github.com/favicon.ico"
    mrkdwn_in   =  ["pretext", "text"]
    pretext     =  ":robot_face: *Socialismbot*"
    text        =  "<@${local.socialismbot}> is Boston DSA's beautiful Marxist robot and he's here to help you!\nType `/welcome` in any chat to see this message again."
  }

  slash_response {
    response_type = "ephemeral"
    attachments   = [
      "${local.welcome}",
      "${local.guidelines}",
      "${local.channels}",
      "${local.bot}"
    ]
  }

  event_response {
    attachments = [
      "${local.welcome}",
      "${local.guidelines}",
      "${local.channels}",
      "${local.bot}"
    ]
  }

  weekly_reminders {
    channel     = "${local.generaldiscussion}"
    attachments = [
      {
        actions   = [
          {
            text = "Learn More"
            type = "button"
            url  = "https://get.slack.help/hc/en-us/articles/115000769927-Message-and-file-threads"
          }
        ]
        color     = "#C9283E"
        fallback  = "Weekly Slack reminders"
        fields    = [
          {
            title = "Ask Questions!"
            value = "Feel free to ask a question any time in any channel. _We are all here to help each other!_ The <#${local.ask_sc}> or <#${local.slack_meta}> channels are a great place to start."
          },
          {
            title = "Limits"
            value = "Please limit your contributions to a *single post at a time*. If you need to say more consider _editing_ your original message instead of posting a new one.\nThis helps members participate in an organized manner."
          },
          {
            title = "Threads"
            value = "If you'd like to get involved in a conversation please *join or start a thread* to avoid derailing other conversations by posting directly in the channel."
          }
        ],
        footer      = "<https://github.com/BostonDSA/socialismbot|BostonDSA/socialismbot>"
        footer_icon = "https://assets-cdn.github.com/favicon.ico"
        mrkdwn_in = ["fields", "pretext"]
        pretext   = ":alarm_clock: *Weekly Slack Reminders*"
      }
    ]
  }

  weekly_reminders_sns {
    Records = [
      {
        Sns {
          Message = "${jsonencode(local.weekly_reminders)}"
        }
      }
    ]
  }
}

data archive_file package {
  type        = "zip"
  source_dir  = "${path.module}/"
  output_path = "${path.module}/package.zip"
}

data aws_iam_role role {
  name = "${var.role_name}"
}

module slash_command {
  source         = "amancevice/slackbot-slash-command/aws"
  version        = "10.0.0"
  api_name       = "${var.api_name}"
  kms_key_arn    = "${var.kms_key_arn}"
  lambda_tags    = "${var.tags}"
  log_group_tags = "${var.tags}"
  response       = "${local.slash_response}"
  role_name      = "${var.role_name}"
  secret_name    = "${var.secret_name}"
  slash_command  = "welcome"
}

resource aws_cloudwatch_event_rule weekly_reminders {
  description         = "Post weekly reminders to Slack"
  name                = "slack-post-reminders"
  schedule_expression = "cron(0 14 ? * MON *)"
}

resource aws_cloudwatch_event_target weekly_reminders {
  rule  = "${aws_cloudwatch_event_rule.weekly_reminders.name}"
  arn   = "${var.post_message_topic_arn}"
  input = "${jsonencode("${local.weekly_reminders}")}"
}

resource aws_cloudwatch_log_group callback_logs {
  name              = "/aws/lambda/${aws_lambda_function.team_join.function_name}"
  retention_in_days = 30
  tags              = "${var.tags}"
}

resource aws_lambda_function team_join {
  description      = "Publish Google Calendar events to Slack"
  filename         = "${data.archive_file.package.output_path}"
  function_name    = "slack-socialismbot-event-team-join"
  handler          = "index.handler"
  memory_size      = 1024
  role             = "${data.aws_iam_role.role.arn}"
  runtime          = "nodejs8.10"
  source_code_hash = "${data.archive_file.package.output_base64sha256}"
  tags             = "${var.tags}"
  timeout          = 3

  environment {
    variables {
      SLACK_SECRET = "slack/socialismbot"
      WELCOME      = "${jsonencode(local.event_response)}"
    }
  }
}

resource aws_lambda_permission team_join {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.team_join.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.team_join.arn}"
}

resource aws_sns_topic team_join {
  name = "slack_${var.api_name}_event_team_join"
}

resource aws_sns_topic_subscription team_join {
  endpoint  = "${aws_lambda_function.team_join.arn}"
  protocol  = "lambda"
  topic_arn = "${aws_sns_topic.team_join.arn}"
}
