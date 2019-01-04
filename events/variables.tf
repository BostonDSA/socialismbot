variable api_name {
  description = "Slackbot name."
}

variable channel_events {
  description = "Events channel ID."
}

variable kms_key_arn {
  description = "KMS Key ARN for Lambdas."
}

variable lambda_tags {
  description = "Lambda function tags."
  default     = {}
  type        = "map"
}

variable role_name {
  description = "Role name for Lambdas."
}

variable secret_name {
  description = "Slackbot secretsmanager secret name."
}
