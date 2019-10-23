output "api_name" {
  description = "REST API Name."
  value       = module.socialismbot.api_name
}

output "role_name" {
  description = "Name of basic execution role for Slackbot lambdas."
  value       = module.socialismbot.role_name
}

output "post_message_topic_arn" {
  description = "Slackbot post message SNS topic ARN."
  value       = module.socialismbot.post_message_topic_arn
}

output "post_ephemeral_topic_arn" {
  description = "Slackbot post ephemeral SNS topic ARN."
  value       = module.socialismbot.post_ephemeral_topic_arn
}

