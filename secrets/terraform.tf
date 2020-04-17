terraform {
  backend s3 {
    bucket = "terraform.bostondsa.org"
    key    = "socialismbot-secrets.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 0.12"
}

provider aws {
  version = "~> 2.7"
}

locals {
  release                  = var.release
  repo                     = "https://github.com/BostonDSA/socialismbot"
  slack_client_id          = var.slack_client_id
  slack_client_secret      = var.slack_client_secret
  slack_oauth_redirect_uri = var.slack_oauth_redirect_uri
  slack_signing_secret     = var.slack_signing_secret
  slack_signing_version    = var.slack_signing_version
  slack_token              = var.slack_token

  tags = {
    App     = "socialismbot"
    Repo    = local.repo
    Release = local.release
  }
}

module secrets {
  source                   = "amancevice/slackbot-secrets/aws"
  version                  = "~> 3.0"
  kms_key_alias            = "alias/slack/socialismbot"
  secret_name              = "slack/socialismbot"
  kms_key_tags             = local.tags
  secret_tags              = local.tags
  slack_client_id          = local.slack_client_id
  slack_client_secret      = local.slack_client_secret
  slack_oauth_redirect_uri = local.slack_oauth_redirect_uri
  slack_signing_secret     = local.slack_signing_secret
  slack_signing_version    = local.slack_signing_version
  slack_token              = local.slack_token

  secrets = {
    SLACK_LEGACY_TOKEN = var.slack_legacy_token
  }
}

output kms_key_alias {
  description = "KMS key alias"
  value       = module.secrets.kms_key_alias
}

output kms_key {
  description = "KMS key"
  value       = module.secrets.kms_key
}

output secret {
  description = "Slackbot SecretsManager secret"
  value       = module.secrets.secret
}

output secret_version {
  description = "Slackbot SecretsManager secret version"
  value       = module.secrets.secret_version
  sensitive   = true
}

variable release {
  description = "Release tag"
}

variable slack_client_id {
  description = "Slack Client ID"
}

variable slack_client_secret {
  description = "Slack Client Secret"
}

variable slack_legacy_token {
  description = "Slack legacy OAuth token"
}

variable slack_oauth_redirect_uri {
  description = "Slack OAuth redirect URI"
  default     = null
}

variable slack_signing_secret {
  description = "Slack signing secret"
}

variable slack_signing_version {
  description = "Slack signing version"
  default     = "v0"
}

variable slack_token {
  description = "Slack bot OAuth token"
}
