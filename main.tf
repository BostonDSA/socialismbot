provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
  version    = "~> 1.27"
}

module "socialismbot" {
  source                  = "amancevice/slackbot/aws"
  version                 = "1.2.0"
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
  version            = "0.0.4"
  api_name           = "${module.socialismbot.api_name}"
  dialog_topic       = "report_message_dialog"
  moderation_channel = "G7FAX48KX"
  # moderation_channel = "GB1SLKKL7"
  remove_topic       = "remove_message"
  report_topic       = "report_message_post"
  role_arn           = "${module.socialismbot.slackbot_role_arn}"
  secret             = "${module.socialismbot.secret}"
}

module "socialismbot_sns_messenger" {
  source   = "amancevice/slackbot-sns-messenger/aws"
  version  = "3.1.0"
  api_name = "${module.socialismbot.api_name}"
  role_arn = "${module.socialismbot.slackbot_role_arn}"
  secret   = "${module.socialismbot.secret}"
}
