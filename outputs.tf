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

output "callback_resource_ids" {
  description = "API Gateway Resource IDs for Slack callbacks."
  value       = "${module.socialismbot.callback_resource_ids}"
}

output "callback_topic_arns" {
  description = "SNS topics for Slack callbacks."
  value       = ["${module.socialismbot.callback_topic_arns}"]
}

output "callbacks_request_url" {
  description = "Callbacks Request URL."
  value        = "${module.socialismbot.callbacks_request_url}"
}

output "secrets_policy_arn" {
  description = "Slackbot KMS key decryption permission policy ARN."
  value       = "${module.socialismbot.secrets_policy_arn}"
}

output "event_resource_ids" {
  description = "API Gateway Resource IDs for Slack events."
  value       = "${module.socialismbot.event_resource_ids}"
}

output "event_topic_arns" {
  description = "SNS topics for Slack events."
  value       = ["${module.socialismbot.event_topic_arns}"]
}

output "events_request_url" {
  description = "Events Request URL."
  value       = "${module.socialismbot.events_request_url}"
}

output "kms_key_id" {
  description = "KMS Key ID."
  value       = "${module.socialismbot.kms_key_id}"
}

output "secret" {
  description = "Slackbot SecretsManager secret name."
  value       = "${module.socialismbot.secret}"
}

output "slackbot_role_arn" {
  description = "ARN of basic execution role for Slackbot lambdas."
  value       = "${module.socialismbot.slackbot_role_arn}"
}

output "slackbot_sns_messenger_topic_arn" {
  description = "SNS Topic ARN for publishing messages to Slack."
  value       = "${module.socialismbot_sns_messenger.topic_arn}"
}

output "slash_commands_request_url" {
  description = "Slash commands base URL."
  value       = "${module.socialismbot.slash_commands_request_url}"
}

output "slash_commands_resource_id" {
  description = "Slash Command resource ID."
  value       = "${module.socialismbot.slash_commands_resource_id}"
}

output "mod_topic_arns" {
  description = "Moderator SNS Topic ARNs."
  value       = ["${module.socialismbot_mod.topic_arns}"]
}
