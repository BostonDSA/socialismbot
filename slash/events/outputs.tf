output topic_arn {
  description = "Post events SNS topic ARN."
  value       = "${aws_sns_topic.topic.arn}"
}
