output slack_post_message_topic_arn {
  description = "Slackbot post message SNS topic ARN."
  value       = "${module.socialismbot.slack_post_message_topic_arn}"
}

output slack_post_ephemeral_topic_arn {
  description = "Slackbot post ephemeral SNS topic ARN."
  value       = "${module.socialismbot.slack_post_ephemeral_topic_arn}"
}
