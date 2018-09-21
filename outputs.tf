output "api_execution_arn" {
  description = "REST API deployment execution ARN."
  value       = "${module.socialismbot.api_execution_arn}"
}

output "api_invoke_url" {
  description = "REST API deployment invocation URL."
  value       = "${module.socialismbot.api_invoke_url}"
}

output "api_name" {
  description = "REST API Name."
  value       = "${module.socialismbot.api_name}"
}

output "api_proxy_resource_id" {
  description = "API Gateway proxy resource ID."
  value       = "${module.socialismbot.api_proxy_resource_id}"
}

output "kms_key_id" {
  description = "KMS Key ID."
  value       = "${module.socialismbot.kms_key_id}"
}

output "lambda" {
  description = "API Lambda name."
  value       = "${module.socialismbot.lambda}"
}

output "mod_topic_arns" {
  description = "Moderator SNS Topic ARNs."
  value       = ["${module.moderator.topic_arns}"]
}

output "request_urls" {
  description = "Callbacks Request URL."
  value        = "${module.socialismbot.request_urls}"
}

output "role_name" {
  description = "Role for Slackbot lambdas."
  value       = "${module.socialismbot.role}"
}

output "secret_name" {
  description = "Slackbot SecretsManager secret name."
  value       = "${module.socialismbot.secret}"
}

output "secrets_policy_arn" {
  description = "Slackbot KMS key decryption permission policy ARN."
  value       = "${module.socialismbot.secrets_policy_arn}"
}

output "slackbot_sns_messenger_topic_arn" {
  description = "SNS Topic ARN for publishing messages to Slack."
  value       = "${module.messenger.topic_arn}"
}
