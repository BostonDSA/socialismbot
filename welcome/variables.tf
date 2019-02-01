variable api_name {
  description = "Slackbot name."
}

variable kms_key_arn {
  description = "KMS Key ARN for Lambda."
}

variable post_message_topic_arn {
  description = "Slackbot post message SNS topic ARN."
}

variable role_name {
  description = "Role name for Lambda."
}

variable secret_name {
  description = "Slackbot secretsmanager secret name."
}

variable tags {
  description = "Lambda function tags."
  type        = "map"
  default     = {}
}
