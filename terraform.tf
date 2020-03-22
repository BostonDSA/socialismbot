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
  release = var.release
  repo    = "https://github.com/BostonDSA/socialismbot.git"

  # Useful Slack chanel IDs
  channel_events  = "C7F7Z0WJG"
  channel_mods    = "G7FAX48KX"
  channel_testing = "GB1SLKKL7"

  tags = {
    App     = "socialismbot"
    Release = local.release
    Repo    = local.repo
  }
}

# Get information _about_ Slackbot secret, but not the secrets themselves
data "terraform_remote_state" "secrets" {
  backend = "s3"
  config = {
    bucket  = "terraform.bostondsa.org"
    key     = "socialismbot-secrets.tfstate"
    region  = "us-east-1"
    profile = "bdsa"
  }
}

# Core slackbot app
module "socialismbot" {
  source         = "amancevice/slackbot/aws"
  version        = "~> 15.0"
  api_name       = "socialismbot"
  api_stage_name = "v1"
  app_name       = "slack-socialismbot"
  base_url       = "/slack"
  kms_key_id     = data.terraform_remote_state.secrets.outputs.kms_key_id
  lambda_tags    = local.tags
  log_group_tags = local.tags
  role_tags      = local.tags
  secret_name    = data.terraform_remote_state.secrets.outputs.secret_name
}

# Events module for posting daily events
module "events" {
  source         = "./events"
  api_name       = module.socialismbot.api_name
  kms_key_arn    = module.socialismbot.kms_key_arn
  role_name      = module.socialismbot.role_name
  slackbot_topic = module.socialismbot.topic_name
  secret_name    = module.socialismbot.secret_name
  channel        = local.channel_events
  tags           = local.tags
}

# Invite members to Slack
module "invite" {
  source         = "./invite"
  api_name       = module.socialismbot.api_name
  kms_key_arn    = module.socialismbot.kms_key_arn
  role_name      = module.socialismbot.role_name
  secret_name    = module.socialismbot.secret_name
  slackbot_topic = module.socialismbot.topic_name
  tags           = local.tags
}

# Moderator module for allowing members to report messages to mods
module "mods" {
  source         = "./mods"
  api_name       = module.socialismbot.api_name
  kms_key_arn    = module.socialismbot.kms_key_arn
  role_name      = module.socialismbot.role_name
  secret_name    = module.socialismbot.secret_name
  slackbot_topic = module.socialismbot.topic_name
  channel        = local.channel_mods
  tags           = local.tags
}

# Welcome module for welcoming members to the Slack
module "welcome" {
  source         = "./welcome"
  api_name       = module.socialismbot.api_name
  kms_key_arn    = module.socialismbot.kms_key_arn
  role_name      = module.socialismbot.role_name
  secret_name    = module.socialismbot.secret_name
  slackbot_topic = module.socialismbot.topic_name
  tags           = local.tags

  legacy_post_message_topic = aws_sns_topic.legacy_post_message.name
}

resource "aws_sns_topic" "legacy_post_message" {
  name = "slack-socialismbot-post-message"
}

resource "aws_sns_topic" "legacy_post_ephemeral" {
  name = "slack-socialismbot-post-ephemeral"
}

resource "aws_sns_topic_subscription" "legacy_post_message" {
  endpoint  = module.socialismbot.lambda_post_message_arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.legacy_post_message.arn
}

resource "aws_sns_topic_subscription" "legacy_post_ephemeral" {
  endpoint  = module.socialismbot.lambda_post_ephemeral_arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.legacy_post_ephemeral.arn
}

output "api_name" {
  description = "REST API Name."
  value       = module.socialismbot.api_name
}

output "role_name" {
  description = "Name of basic execution role for Slackbot lambdas."
  value       = module.socialismbot.role_name
}

output "post_message_topic_arn" {
  description = "Slackbot post message SNS topic ARN."
  value       = module.socialismbot.topic_arn
}

output "post_ephemeral_topic_arn" {
  description = "Slackbot post ephemeral SNS topic ARN."
  value       = module.socialismbot.topic_arn
}

variable "release" {
  description = "Release tag."
}