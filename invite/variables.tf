variable api_name {
  description = "Slackbot REST API Gateway Name."
}

variable kms_key_arn {
  description = "KMS Key ARN for Lambdas."
}

variable role_name {
  description = "Slackbot role name."
}

variable secret_name {
  description = "Slackbot secretsmanager secret name."
}

variable tags {
  description = "AWS resource tags."
  type        = "map"
  default     = {}
}
