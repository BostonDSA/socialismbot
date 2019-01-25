module slash_command {
  source         = "amancevice/slackbot-slash-command/aws"
  version        = "10.0.0"
  api_name       = "${var.api_name}"
  kms_key_arn    = "${var.kms_key_arn}"
  lambda_tags    = "${var.tags}"
  log_group_tags = "${var.tags}"
  role_name      = "${var.role_name}"
  secret_name    = "${var.secret_name}"
  slash_command  = "welcome"

  response {
    response_type = "ephemeral"
    text          = "Welcome to DSA!"
  }
}
