provider aws {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
  version    = "~> 1.41"
}

locals {
  events    = "C7F7Z0WJG"
  team_mods = "G7FAX48KX"
  testing   = "GB1SLKKL7"
}

module socialismbot {
  source                  = "amancevice/slackbot/aws"
  version                 = "6.2.2"
  api_name                = "socialismbot"
  slack_bot_access_token  = "${var.slack_bot_access_token}"
  slack_client_id         = "${var.slack_client_id}"
  slack_client_secret     = "${var.slack_client_secret}"
  slack_signing_secret    = "${var.slack_signing_secret}"
  slack_user_access_token = "${var.slack_user_access_token}"
}

module moderator {
  source            = "amancevice/slackbot-mod/aws"
  version           = "0.4.0"
  api_name          = "${module.socialismbot.api_name}"
  moderator_channel = "${local.testing}"
  role              = "${module.socialismbot.role_name}"
  secret            = "${module.socialismbot.secret_name}"
}

module messenger {
  source      = "amancevice/slackbot-sns-messenger/aws"
  version     = "6.0.0"
  api_name    = "${module.socialismbot.api_name}"
  role_name   = "${module.socialismbot.role_name}"
  secret_name = "${module.socialismbot.secret_name}"
}
