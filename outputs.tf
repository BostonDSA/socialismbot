output mod_topic_arns {
  description = "Moderator SNS Topic ARNs."
  value       = ["${module.moderator.topic_arns}"]
}

output socialismbot_api_execution_arn {
  description = "REST API deployment execution ARN."
  value       = "${module.socialismbot.api_execution_arn}"
}

output socialismbot_api_name {
  description = "REST API Name."
  value       = "${module.socialismbot.api_name}"
}

output socialismbot_api_proxy_resource_id {
  description = "API Gateway proxy resource ID."
  value       = "${module.socialismbot.api_proxy_resource_id}"
}

output socialismbot_kms_key_arn {
  description = "KMS Key ARN."
  value       = "${module.socialismbot.kms_key_arn}"
}

output socialismbot_kms_key_id {
  description = "KMS Key ID."
  value       = "${module.socialismbot.kms_key_id}"
}

output socialismbot_lambda_name {
  description = "API Lambda name."
  value       = "${module.socialismbot.lambda_name}"
}

output socialismbot_role_name {
  description = "Role for Slackbot lambdas."
  value       = "${module.socialismbot.role_name}"
}

output socialismbot_secret_name {
  description = "Slackbot SecretsManager secret name."
  value       = "${module.socialismbot.secret_name}"
}

output socialismbot_secrets_policy_arn {
  description = "Slackbot KMS key decryption permission policy ARN."
  value       = "${module.socialismbot.secrets_policy_arn}"
}

output messenger_topic_arn {
  description = "SNS Topic ARN for publishing messages to Slack."
  value       = "${module.messenger.topic_arn}"
}

output slash_events_topic_arn {
  description = "Post events SNS topic ARN."
  value       = "${module.slash_events.topic_arn}"
}
