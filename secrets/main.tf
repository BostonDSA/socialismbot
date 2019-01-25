provider aws {
  version = "~> 1.52"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  profile    = "${var.aws_profile}"
  region     = "${var.aws_region}"
}

locals {
  tags {
    App     = "socialismbot"
    Repo    = "${var.repo}"
    Release = "${var.release}"
  }
}

module secrets {
  source               = "amancevice/slackbot-secrets/aws"
  version              = "0.1.1"
  kms_key_alias        = "alias/slack/socialismbot"
  kms_key_tags         = "${local.tags}"
  secret_name          = "slack/socialismbot"
  secret_tags          = "${local.tags}"
  slack_bot_token      = "${var.slack_bot_token}"
  slack_client_id      = "${var.slack_client_id}"
  slack_client_secret  = "${var.slack_client_secret}"
  slack_legacy_token   = "${var.slack_legacy_token}"
  slack_signing_secret = "${var.slack_signing_secret}"
  slack_user_token     = "${var.slack_user_token}"
}
