// Events
output "events_pubsub_topics" {
  description = "Pub/Sub topics."
  value       = "${module.events.pubsub_topics}"
}

// Interactive Components
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

// URLs
output "request_urls" {
  description = "Slack Request URLs."

  value {
    chapter_sms_slash_command = "${module.chapter_sms.slash_command_url}"
    events                    = "${module.events.request_url}"
    interactive_components    = "${module.interactive_components.request_url}"
    slack_drive_slash_command = "${module.slack_drive.slash_command_url}"
  }
}
