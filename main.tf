provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
  version    = "~> 1.29"
}

locals {
  events    = "C7F7Z0WJG"
  team_mods = "G7FAX48KX"
  testing   = "GB1SLKKL7"
}

module "socialismbot" {
  source                  = "amancevice/slackbot/aws"
  version                 = "4.0.0"
  api_name                = "socialismbot"
  slack_bot_access_token  = "${var.slack_bot_access_token}"
  slack_client_id         = "${var.slack_client_id}"
  slack_client_secret     = "${var.slack_client_secret}"
  slack_signing_secret    = "${var.slack_signing_secret}"
  slack_workspace_token   = "${var.slack_workspace_token}"
  slack_user_access_token = "${var.slack_user_access_token}"
}

module "moderator" {
  source            = "amancevice/slackbot-mod/aws"
  version           = "0.3.0"
  api_name          = "${module.socialismbot.api_name}"
  moderator_channel = "${local.team_mods}"
  role              = "${module.socialismbot.role}"
  secret            = "${module.socialismbot.secret}"
}

module "messenger" {
  source   = "amancevice/slackbot-sns-messenger/aws"
  version  = "5.0.0"
  api_name = "${module.socialismbot.api_name}"
  role     = "${module.socialismbot.role}"
  secret   = "${module.socialismbot.secret}"
}
