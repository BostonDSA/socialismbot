terraform {
  backend "s3" {
    bucket = "terraform.bostondsa.org"
    key    = "socialismbot.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.7"
}

locals {
  repo = "https://github.com/BostonDSA/socialismbot.git"

  # Useful Slack chanel IDs
  channel_events  = "C7F7Z0WJG"
  channel_mods    = "G7FAX48KX"
  channel_testing = "GB1SLKKL7"

  tags = {
    App     = "socialismbot"
    Version = var.VERSION
    Repo    = local.repo
  }
}

# Get information _about_ Slackbot secret, but not the secrets themselves
data terraform_remote_state secrets {
  backend = "s3"
  config = {
    bucket  = "terraform.bostondsa.org"
    key     = "socialismbot-secrets.tfstate"
    region  = "us-east-1"
    profile = "bdsa"
  }
}

# Core slackbot app
module socialismbot {
  source         = "amancevice/slackbot/aws"
  version        = "~> 18.1"
  api_name       = "socialismbot"
  api_stage_name = "v1"
  app_name       = "slack-socialismbot"
  base_url       = "/slack"
  kms_key_arn    = data.terraform_remote_state.secrets.outputs.kms_key.arn
  lambda_tags    = local.tags
  log_group_tags = local.tags
  role_tags      = local.tags
  secret_name    = data.terraform_remote_state.secrets.outputs.secret.name
}

module post_message {
  source               = "amancevice/slackbot-chat/aws"
  version              = "~> 1.0"
  api_name             = module.socialismbot.api.name
  chat_method          = "postMessage"
  kms_key_arn          = data.terraform_remote_state.secrets.outputs.kms_key.arn
  lambda_description   = "Post Slack message via SNS"
  lambda_function_name = "slack-socialismbot-api-post-message"
  lambda_tags          = local.tags
  lambda_timeout       = 15
  log_group_tags       = local.tags
  role_arn             = module.socialismbot.role.arn
  secret_name          = data.terraform_remote_state.secrets.outputs.secret.name
  topic_arn            = module.socialismbot.topic.arn
}

module post_ephemeral {
  source               = "amancevice/slackbot-chat/aws"
  version              = "~> 1.0"
  api_name             = module.socialismbot.api.name
  chat_method          = "postEphemeral"
  kms_key_arn          = data.terraform_remote_state.secrets.outputs.kms_key.arn
  lambda_description   = "Post Slack message via SNS"
  lambda_function_name = "slack-socialismbot-api-post-ephemeral"
  lambda_tags          = local.tags
  lambda_timeout       = 15
  log_group_tags       = local.tags
  role_arn             = module.socialismbot.role.arn
  secret_name          = data.terraform_remote_state.secrets.outputs.secret.name
  topic_arn            = module.socialismbot.topic.arn
}


# Events module for posting daily events
module events {
  source         = "./events"
  package        = "./dist/events.zip"
  api_name       = module.socialismbot.api.name
  kms_key_arn    = data.terraform_remote_state.secrets.outputs.kms_key.arn
  role_name      = module.socialismbot.role.name
  slackbot_topic = module.socialismbot.topic.name
  secret_name    = data.terraform_remote_state.secrets.outputs.secret.name
  channel        = local.channel_events
  tags           = local.tags
}

# Invite members to Slack
module invite {
  source         = "./invite"
  package        = "./dist/invite.zip"
  api_name       = module.socialismbot.api.name
  kms_key_arn    = data.terraform_remote_state.secrets.outputs.kms_key.arn
  role_name      = module.socialismbot.role.name
  secret_name    = data.terraform_remote_state.secrets.outputs.secret.name
  slackbot_topic = module.socialismbot.topic.name
  tags           = local.tags
}

# Moderator module for allowing members to report messages to mods
module mods {
  source         = "./mods"
  package        = "./dist/mods.zip"
  api_name       = module.socialismbot.api.name
  kms_key_arn    = data.terraform_remote_state.secrets.outputs.kms_key.arn
  role_name      = module.socialismbot.role.name
  secret_name    = data.terraform_remote_state.secrets.outputs.secret.name
  slackbot_topic = module.socialismbot.topic.name
  channel        = local.channel_mods
  tags           = local.tags
}

# Welcome module for welcoming members to the Slack
module welcome {
  source         = "./welcome"
  package        = "./dist/welcome.zip"
  api_name       = module.socialismbot.api.name
  kms_key_arn    = data.terraform_remote_state.secrets.outputs.kms_key.arn
  role_name      = module.socialismbot.role.name
  secret_name    = data.terraform_remote_state.secrets.outputs.secret.name
  slackbot_topic = module.socialismbot.topic.name
  tags           = local.tags

  legacy_post_message_topic = aws_sns_topic.legacy_post_message.name
}

resource aws_sns_topic legacy_post_message {
  name = "slack-socialismbot-post-message"
}

resource aws_sns_topic legacy_post_ephemeral {
  name = "slack-socialismbot-post-ephemeral"
}

resource aws_sns_topic_subscription legacy_post_message {
  endpoint  = module.post_message.lambda.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.legacy_post_message.arn
}

resource aws_sns_topic_subscription legacy_post_ephemeral {
  endpoint  = module.post_ephemeral.lambda.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.legacy_post_ephemeral.arn
}

output api_name {
  description = "REST API Name"
  value       = module.socialismbot.api.name
}

output role_name {
  description = "Name of basic execution role for Slackbot lambdas"
  value       = module.socialismbot.role.name
}

output post_message_topic_arn {
  description = "Slackbot post message SNS topic ARN"
  value       = module.socialismbot.topic.arn
}

output post_ephemeral_topic_arn {
  description = "Slackbot post ephemeral SNS topic ARN"
  value       = module.socialismbot.topic.arn
}

variable VERSION {
  description = "Release tag name"
}
