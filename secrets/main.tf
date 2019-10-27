provider aws {
  version = "~> 2.7"
}

locals {
  tags = {
    App     = "socialismbot"
    Repo    = var.repo
    Release = var.release
  }
}

module secrets {
  source                   = "amancevice/slackbot-secrets/aws"
  version                  = "~> 2.0"
  kms_key_alias            = "alias/slack/socialismbot"
  secret_name              = "slack/socialismbot"
  kms_key_tags             = local.tags
  secret_tags              = local.tags
  slack_client_id          = var.slack_client_id
  slack_client_secret      = var.slack_client_secret
  slack_oauth_redirect_uri = var.slack_oauth_redirect_uri
  slack_signing_secret     = var.slack_signing_secret
  slack_signing_version    = var.slack_signing_version
  slack_token              = var.slack_token

  secrets = {
    SLACK_LEGACY_TOKEN = var.slack_legacy_token
  }
}
