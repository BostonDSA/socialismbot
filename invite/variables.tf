variable "api_name" {
  description = "Slackbot REST API Gateway Name"
}

variable "kms_key_arn" {
  description = "KMS Key ARN for Lambdas"
}

variable "package" {
  description = "Lambda zip package path"
}

variable "role_name" {
  description = "Slackbot role name"
}

variable "secret_name" {
  description = "Slackbot secretsmanager secret name"
}

variable "slackbot_topic" {
  description = "Slackbot SNS topic name"
}

variable "tags" {
  description = "AWS resource tags"
  type        = map(string)
  default     = {}
}
