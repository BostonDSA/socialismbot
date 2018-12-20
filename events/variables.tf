variable api_name {
  description = "Slackbot name."
}

variable channel_events {
  description = "Events channel ID."
}

variable kms_key_arn {
  description = "KMS Key ARN for Lambdas."
}

variable role_name {
  description = "Role name for Lambdas."
}

variable secret_name {
  description = "Slackbot secretsmanager secret name."
}
