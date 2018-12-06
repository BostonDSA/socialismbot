provider aws {
  version = "~> 1.41"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  profile    = "${var.aws_profile}"
  region     = "${var.aws_region}"
}

provider archive {
  version = "~> 1.0"
}

locals {
  events    = "C7F7Z0WJG"
  team_mods = "G7FAX48KX"
  testing   = "GB1SLKKL7"
}

data aws_kms_key key {
  key_id = "alias/aws/secretsmanager"
}

data aws_secretsmanager_secret secret {
  name = "google/socialismbot"
}

data aws_iam_policy_document google {
  statement {
    sid       = "DecryptGoogleServiceAcctSecret"
    actions   = ["kms:Decrypt"]
    resources = ["${data.aws_kms_key.key.arn}"]
  }

  statement {
    sid       = "GetSlackSecretValue"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["${data.aws_secretsmanager_secret.secret.arn}"]
  }
}

resource aws_iam_policy google {
  name   = "google-socialismbot"
  policy = "${data.aws_iam_policy_document.google.json}"
}

module socialismbot {
  source                  = "amancevice/slackbot/aws"
  version                 = "8.2.0"
  api_name                = "socialismbot"
  base_url                = "/slack"
  role_policy_attachments = ["${aws_iam_policy.google.arn}"]
  slack_bot_access_token  = "${var.slack_bot_access_token}"
  slack_client_id         = "${var.slack_client_id}"
  slack_client_secret     = "${var.slack_client_secret}"
  slack_signing_secret    = "${var.slack_signing_secret}"
  slack_user_access_token = "${var.slack_user_access_token}"
}

module messenger {
  source      = "amancevice/slackbot-sns-messenger/aws"
  version     = "8.0.0"
  api_name    = "${module.socialismbot.api_name}"
  kms_key_arn = "${module.socialismbot.kms_key_arn}"
  role_name   = "${module.socialismbot.role_name}"
  secret_name = "${module.socialismbot.secret_name}"
}

module moderator {
  source            = "amancevice/slackbot-mod/aws"
  version           = "0.6.1"
  api_name          = "${module.socialismbot.api_name}"
  moderator_channel = "${local.team_mods}"
  role              = "${module.socialismbot.role_name}"
  secret            = "${module.socialismbot.secret_name}"
}

module slash_events {
  source             = "./slash/events"
  google_calendar_id = "${var.google_calendar_id}"
  api_name           = "${module.socialismbot.api_name}"
  kms_key_arn        = "${module.socialismbot.kms_key_arn}"
  role_name          = "${module.socialismbot.role_name}"
  secret_name        = "${module.socialismbot.secret_name}"
  topic_arn          = "${module.messenger.topic_arn}"
}
