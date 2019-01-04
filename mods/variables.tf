variable api_name {
  description = "Slackbot REST API Gateway Name."
}

variable channel_mods {
  description = "Slack moderator channel ID."
}

variable lambda_tags {
  description = "Lambda function tags."
  default     = {}
  type        = "map"
}

variable role_name {
  description = "Slackbot role name."
}

variable secret_name {
  description = "Name of Slackbot secret in AWS SecretsManager."
}
