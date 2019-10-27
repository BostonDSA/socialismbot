variable api_name {
  description = "Slackbot name."
}

variable kms_key_arn {
  description = "KMS Key ARN for Lambda."
}

variable role_name {
  description = "Role name for Lambda."
}

variable secret_name {
  description = "Slackbot secretsmanager secret name."
}

variable slackbot_topic {
  description = "Slackbot SNS topic name."
}

variable tags {
  description = "Lambda function tags."
  type        = "map"
  default     = {}
}

variable legacy_post_message_topic {
  description = "Slackbot legacy post message SNS topic name."
}
