output "mod_topic_arns" {
  description = "Moderator SNS Topic ARNs."
  value       = ["${module.moderator.topic_arns}"]
}

output "socialismbot_api_execution_arn" {
  description = "REST API deployment execution ARN."
  value       = "${module.socialismbot.api_execution_arn}"
}

output "socialismbot_api_invoke_url" {
  description = "REST API deployment invocation URL."
  value       = "${module.socialismbot.api_invoke_url}"
}

output "socialismbot_api_name" {
  description = "REST API Name."
  value       = "${module.socialismbot.api_name}"
}

output "socialismbot_api_proxy_resource_id" {
  description = "API Gateway proxy resource ID."
  value       = "${module.socialismbot.api_proxy_resource_id}"
}

output "socialismbot_kms_key_id" {
  description = "KMS Key ID."
  value       = "${module.socialismbot.kms_key_id}"
}

output "socialismbot_lambda" {
  description = "API Lambda name."
  value       = "${module.socialismbot.lambda}"
}

output "socialismbot_request_urls" {
  description = "Callbacks Request URL."
  value        = "${module.socialismbot.request_urls}"
}

output "socialismbot_role" {
  description = "Role for Slackbot lambdas."
  value       = "${module.socialismbot.role}"
}

output "socialismbot_secret" {
  description = "Slackbot SecretsManager secret name."
  value       = "${module.socialismbot.secret}"
}

output "socialismbot_secrets_policy_arn" {
  description = "Slackbot KMS key decryption permission policy ARN."
  value       = "${module.socialismbot.secrets_policy_arn}"
}

output "messenger_topic_arn" {
  description = "SNS Topic ARN for publishing messages to Slack."
  value       = "${module.messenger.topic_arn}"
}
