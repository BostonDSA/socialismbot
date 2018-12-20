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

data terraform_remote_state socialismbot {
  backend = "s3"
  config {
    bucket  = "terraform.bostondsa.org"
    key     = "socialismbot.tfstate"
    region  = "us-east-1"
    profile = "bdsa"
  }
}

module events {
  source             = "./events"
  api_name           = "${data.terraform_remote_state.socialismbot.api_name}"
  kms_key_arn        = "${data.terraform_remote_state.socialismbot.kms_key_arn}"
  role_name          = "${data.terraform_remote_state.socialismbot.role_name}"
  slack_secret_name  = "${data.terraform_remote_state.socialismbot.secret_name}"
  channel_events     = "${local.channel_events}"
}

module mods {
  source            = "./mods"
  api_name          = "${data.terraform_remote_state.socialismbot.api_name}"
  role_name         = "${data.terraform_remote_state.socialismbot.role_name}"
  slack_secret_name = "${data.terraform_remote_state.socialismbot.secret_name}"
  channel_mods      = "${local.channel_mods}"
}
