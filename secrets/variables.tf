variable aws_access_key_id {
  description = "AWS Access Key ID."
  default     = ""
}

variable aws_secret_access_key {
  description = "AWS Secret Access Key."
  default     = ""
}

variable aws_profile {
  description = "AWS Profile."
  default     = ""
}

variable aws_region {
  description = "AWS Region."
  default     = "us-east-1"
}

variable release {
  description = "Release tag."
}

variable repo {
  description = "Project repository."
}

variable slack_client_id {
  description = "Slack Client ID."
}

variable slack_client_secret {
  description = "Slack Client Secret."
}

variable slack_legacy_token {
  description = "Slack legacy OAuth token."
}

variable slack_oauth_redirect_uri {
  description = "Slack OAuth redirect URI."
  default     = ""
}

variable slack_signing_secret {
  description = "Slack signing secret."
}

variable slack_signing_version {
  description = "Slack signing version."
  default     = "v0"
}

variable slack_token {
  description = "Slack bot OAuth token."
}

variable slack_user_token {
  description = "Slack user OAuth token."
}
