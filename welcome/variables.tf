variable api_name {
  description = "Slackbot name."
}

variable kms_key_arn {
  description = "KMS Key ARN for Lambda."
}

variable lambda_tags {
  description = "Lambda function tags."
  default     = {}
  type        = "map"
}

variable role_name {
  description = "Role name for Lambda."
}

variable secret_name {
  description = "Slackbot secretsmanager secret name."
}
