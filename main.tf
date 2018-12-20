provider aws {
  version = "~> 1.52"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  profile    = "${var.aws_profile}"
  region     = "${var.aws_region}"
}

locals {
  # Useful Slack chanel IDs
  channel_events  = "C7F7Z0WJG"
  channel_mods    = "G7FAX48KX"
  channel_testing = "GB1SLKKL7"
}

module socialismbot {
  source                  = "amancevice/slackbot/aws"
  version                 = "8.4.1"
  api_name                = "socialismbot"
  base_url                = "/slack"
  slack_bot_access_token  = "${var.slack_bot_access_token}"
  slack_client_id         = "${var.slack_client_id}"
  slack_client_secret     = "${var.slack_client_secret}"
  slack_signing_secret    = "${var.slack_signing_secret}"
  slack_user_access_token = "${var.slack_user_access_token}"
}

module mods {
  source            = "./mods"
  api_name          = "${module.socialismbot.api_name}"
  role_name         = "${module.socialismbot.role_name}"
  slack_secret_name = "${module.socialismbot.slack_secret_name}"
  channel_mods      = "${local.channel_mods}"
}

module events {
  source             = "./events"
  api_name           = "${module.socialismbot.api_name}"
  kms_key_arn        = "${module.socialismbot.kms_key_arn}"
  role_name          = "${module.socialismbot.role_name}"
  slack_secret_name  = "${module.socialismbot.slack_secret_name}"
  channel_events     = "${local.channel_events}"
}
