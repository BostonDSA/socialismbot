locals {
  lambda_filename         = var.package
  lambda_source_code_hash = filebase64sha256(var.package)

  ask_sc            = "C9Z3M55DG"
  generaldiscussion = "C7M1CCBAQ"
  slack_meta        = "C7F6BQBEW"
  socialismbot      = "UAJGYQCQ1"
  testing           = "GB1SLKKL7"

  team_join_filter_policy = {
    id   = ["team_join"]
    type = ["event"]
  }

  welcome = {
    actions = [
      {
        text = "Learn More"
        type = "button"
        url  = "https://get.slack.help/hc/en-us/articles/115000769927-Message-and-file-threads"
      }
    ]
    color = "#f0433a"
    fields = [
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
    ]
    pretext   = ":sparkles: *Welcome to Boston DSA!* :sparkles:"
    mrkdwn_in = ["fields", "pretext", "text"]
    text      = "Take a moment to review the <https://www.dsausa.org/respectful_discussion|DSA Guidelines for Respectful Discussion>.\nMembers should adhere to the <https://bit.ly/BDSACode|Boston DSA Code of Conduct> at all times.\nFor full details, consult the <https://drive.google.com/file/d/0B6OdCRb_vSGzeTV4akFSRHF0NWs/view|Boston DSA Slack Guidelines>"
  }

  channels = {
    actions = [
      {
        text = "Learn More"
        type = "button"
        url  = "https://get.slack.help/hc/en-us/articles/218080037-Getting-started-for-new-members"
      }
    ]
    color = "#C9283E"
    fields = [
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

  bot = {
    actions = [
      {
        text = "Learn More"
        type = "button"
        url  = "https://members.bostondsa.org"
      }
    ]
    color       = "#820333"
    footer      = "<https://github.com/BostonDSA/socialismbot|BostonDSA/socialismbot>"
    footer_icon = "https://assets-cdn.github.com/favicon.ico"
    mrkdwn_in   = ["pretext", "text"]
    pretext     = ":rose: *Socialismbot*"
    text        = "<@${local.socialismbot}> is Boston DSA's beautiful Marxist robot and he's here to help you!\nType `/welcome` in any chat to see this message again.\nVisit members.bostondsa.org for more member onboarding resources!"
  }

  slash_response = {
    response_type = "ephemeral"
    attachments = [
      local.welcome,
      local.channels,
      local.bot,
    ]
  }

  event_response = {
    attachments = [
      local.welcome,
      local.channels,
      local.bot,
    ]
  }

  weekly_reminders = {
    channel = local.generaldiscussion
    attachments = [
      {
        actions = [
          {
            text = "Learn More"
            type = "button"
            url  = "https://get.slack.help/hc/en-us/articles/115000769927-Message-and-file-threads"
          }
        ]
        color    = "#C9283E"
        fallback = "Weekly Slack reminders"
        fields = [
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
        mrkdwn_in   = ["fields", "pretext"]
        pretext     = ":alarm_clock: *Weekly Slack Reminders*"
      }
    ]
  }
}

data aws_iam_role role {
  name = var.role_name
}

data aws_sns_topic slackbot {
  name = var.slackbot_topic
}

data aws_sns_topic legacy_post_message {
  name = var.legacy_post_message_topic
}

module slash_command {
  source         = "amancevice/slackbot-slash-command/aws"
  version        = "~> 14.0"
  api_name       = var.api_name
  kms_key_arn    = var.kms_key_arn
  lambda_tags    = var.tags
  log_group_tags = var.tags
  response       = jsonencode(local.slash_response)
  role_name      = var.role_name
  secret_name    = var.secret_name
  slash_command  = "welcome"
  slackbot_topic = data.aws_sns_topic.slackbot.name
}

resource aws_cloudwatch_event_rule weekly_reminders {
  description         = "Post weekly reminders to Slack"
  name                = "slack-post-reminders"
  schedule_expression = "cron(0 14 ? * MON *)"
}

resource aws_cloudwatch_event_target weekly_reminders {
  rule  = aws_cloudwatch_event_rule.weekly_reminders.name
  arn   = data.aws_sns_topic.legacy_post_message.arn
  input = jsonencode(local.weekly_reminders)
}

resource aws_cloudwatch_log_group team_join_logs {
  name              = "/aws/lambda/${aws_lambda_function.team_join.function_name}"
  retention_in_days = 30
  tags              = var.tags
}

resource aws_lambda_function team_join {
  description      = "Publish Google Calendar events to Slack"
  filename         = local.lambda_filename
  function_name    = "slack-socialismbot-event-team-join"
  handler          = "index.handler"
  memory_size      = 1024
  role             = data.aws_iam_role.role.arn
  runtime          = "nodejs12.x"
  source_code_hash = local.lambda_source_code_hash
  tags             = var.tags
  timeout          = 3

  environment {
    variables = {
      SLACK_SECRET = var.secret_name
      WELCOME      = jsonencode(local.event_response)
    }
  }
}

resource aws_lambda_permission team_join {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.team_join.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.slackbot.arn
}

resource aws_sns_topic_subscription team_join {
  endpoint      = aws_lambda_function.team_join.arn
  protocol      = "lambda"
  topic_arn     = data.aws_sns_topic.slackbot.arn
  filter_policy = jsonencode(local.team_join_filter_policy)
}
