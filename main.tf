provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
  version    = "~> 1.27"
}

module "socialismbot" {
  source                 = "amancevice/slackbot/aws"
  version                = "1.1.2"
  api_name               = "socialismbot"
  slack_access_token     = "${var.slack_access_token}"
  slack_bot_access_token = "${var.slack_bot_access_token}"
  slack_signing_secret   = "${var.slack_signing_secret}"

  callback_ids = [
    "blast",
    "remove_thread",
    "remove_thread_dialog",
    "report_message",
    "report_message_dialog",
    "test"
  ]

  event_types = [
    "channel_rename",
    "group_rename",
    "member_joined_channel",
    "member_left_channel",
    "test"
  ]
}

module "socialismbot_remove_thread" {
  source       = "amancevice/slackbot-remove-thread/aws"
  version      = "0.0.4"
  api_name     = "${module.socialismbot.api_name}"
  mod_channel  = "G7FAX48KX"
  dialog_topic = "remove_thread_dialog"
  remove_topic = "remove_thread"
  role_arn     = "${module.socialismbot.slackbot_role_arn}"
  secret       = "${module.socialismbot.secret}"
}

module "socialismbot_sns_messenger" {
  source   = "amancevice/slackbot-sns-messenger/aws"
  version  = "2.1.2"
  api_name = "${module.socialismbot.api_name}"
  role_arn = "${module.socialismbot.slackbot_role_arn}"
  secret   = "${module.socialismbot.secret}"
}
