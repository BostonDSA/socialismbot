// Events
output "events_request_url" {
  description = "Slack endpoint."
  value       = "${module.events.request_url}"
}

output "events_pubsub_topics" {
  description = "Pub/Sub topics."
  value       = "${module.events.pubsub_topics}"
}

// Interactive Components
output "interactive_components_request_url" {
  description = "Slack endpoint."
  value       = "${module.interactive_components.request_url}"
}

output "interactive_components_pubsub_topics" {
  description = "Pub/Sub topics."
  value       = "${module.interactive_components.pubsub_topics}"
}

// Chapter SMS
output "chapter_sms_sns_topic_arn" {
  description = "AWS Topic ARN."
  value       = "${module.chapter_sms.sns_topic_arn}"
}

output "chapter_sms_sns_topic_subscriptions" {
  description = "AWS Topic ARN."
  value       = "${module.chapter_sms.sns_topic_subscriptions}"
}

output "chapter_sms_slash_command_url" {
  description = "Slack slash command Request URL."
  value       = "${module.chapter_sms.slash_command_url}"
}
