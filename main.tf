provider archive {
  version = "~> 1.1"
}

provider aws {
  version    = "~> 1.55"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  profile    = "${var.aws_profile}"
  region     = "${var.aws_region}"
}

# Useful Slack chanel IDs
locals {
  channel_events  = "C7F7Z0WJG"
  channel_mods    = "G7FAX48KX"
  channel_testing = "GB1SLKKL7"

  lambda_tags {
    App     = "socialismbot"
    Release = "${var.release}"
    Repo    = "${var.repo}"
  }
}

# Get information _about_ Slackbot secret, but not the secrets themselves
data terraform_remote_state secrets {
  backend = "s3"
  config {
    bucket  = "terraform.bostondsa.org"
    key     = "socialismbot-secrets.tfstate"
    region  = "us-east-1"
    profile = "bdsa"
  }
}

# Core slackbot app
module socialismbot {
  source      = "amancevice/slackbot/aws"
  version     = "10.0.0"
  api_name    = "socialismbot"
  base_url    = "/slack"
  secret_arn  = "${data.terraform_remote_state.secrets.secret_arn}"
  kms_key_id  = "${data.terraform_remote_state.secrets.kms_key_id}"
  lambda_tags = "${local.lambda_tags}"
}

# Events module for posting daily events
module events {
  source         = "./events"
  api_name       = "${module.socialismbot.api_name}"
  kms_key_arn    = "${module.socialismbot.kms_key_arn}"
  role_name      = "${module.socialismbot.role_name}"
  secret_name    = "${module.socialismbot.secret_name}"
  channel        = "${local.channel_events}"
  lambda_tags    = "${local.lambda_tags}"
}

# Invite members to Slack
module invite {
  source         = "./invite"
  api_name       = "${module.socialismbot.api_name}"
  kms_key_arn    = "${module.socialismbot.kms_key_arn}"
  role_name      = "${module.socialismbot.role_name}"
  secret_name    = "${module.socialismbot.secret_name}"
  lambda_tags    = "${local.lambda_tags}"
}

# Moderator module for allowing members to report messages to mods
module mods {
  source       = "./mods"
  api_name     = "${module.socialismbot.api_name}"
  kms_key_arn  = "${module.socialismbot.kms_key_arn}"
  role_name    = "${module.socialismbot.role_name}"
  secret_name  = "${module.socialismbot.secret_name}"
  channel      = "${local.channel_mods}"
  lambda_tags  = "${local.lambda_tags}"
}

# Welcome module for welcoming members to the Slack
module welcome {
  source      = "./welcome"
  api_name    = "${module.socialismbot.api_name}"
  kms_key_arn = "${module.socialismbot.kms_key_arn}"
  role_name   = "${module.socialismbot.role_name}"
  secret_name = "${module.socialismbot.secret_name}"
  lambda_tags = "${local.lambda_tags}"
}
