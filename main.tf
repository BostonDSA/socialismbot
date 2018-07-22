provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
  version    = "~> 1.28"
}

locals {
  events    = "C7F7Z0WJG"
  team_mods = "G7FAX48KX"
  testing   = "GB1SLKKL7"
}

module "socialismbot" {
  source                  = "amancevice/slackbot/aws"
  version                 = "2.1.1"
  api_name                = "socialismbot"
  slack_client_id         = "${var.slack_client_id}"
  slack_client_secret     = "${var.slack_client_secret}"
  slack_signing_secret    = "${var.slack_signing_secret}"
  slack_workspace_token   = "${var.slack_workspace_token}"

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

module "messenger" {
  source   = "amancevice/slackbot-sns-messenger/aws"
  version  = "4.0.0"
  api_name = "${module.socialismbot.api_name}"
  role     = "${module.socialismbot.role}"
  secret   = "${module.socialismbot.secret}"
}
