provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
  version    = "~> 1.27"
}

locals {
  events    = "C7F7Z0WJG"
  team_mods = "G7FAX48KX"
  testing   = "GB1SLKKL7"
}

module "socialismbot" {
  source                  = "amancevice/slackbot/aws"
  version                 = "1.3.3"
  api_name                = "socialismbot"
  slack_user_access_token = "${var.slack_user_access_token}"
  slack_bot_access_token  = "${var.slack_bot_access_token}"
  slack_signing_secret    = "${var.slack_signing_secret}"

  event_types = [
    "channel_rename",
    "group_rename",
    "member_joined_channel",
    "member_left_channel",
    "test"
  ]
}

module "socialismbot_mod" {
  source             = "amancevice/slackbot-mod/aws"
  version            = "0.1.2"
  api_name           = "${module.socialismbot.api_name}"
  moderation_channel = "${local.team_mods}"
  role_arn           = "${module.socialismbot.slackbot_role_arn}"
  secret             = "${module.socialismbot.secret}"
}

module "socialismbot_sns_messenger" {
  source   = "amancevice/slackbot-sns-messenger/aws"
  version  = "3.2.0"
  api_name = "${module.socialismbot.api_name}"
  role     = "${module.socialismbot.slackbot_role}"
  secret   = "${module.socialismbot.secret}"
}
