provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
  version    = "~> 1.24"
}

module "socialismbot" {
  source                   = "amancevice/slackbot/aws"
  version                  = "0.2.0"
  api_name                 = "socialismbot"
  auto_encrypt_token       = false
  slack_verification_token = "AQICAHjBa19e4R5qIz6Kx+CVTCK0X24YvSvQn/280b8MKuUc5gG9eDWvcyZEvnHPuSdqnnINAAAAdjB0BgkqhkiG9w0BBwagZzBlAgEAMGAGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMQK+dnddnNS9/DcmVAgEQgDPItLoDrdn3N7KT8VPelqM1UA5rJJ2RaYcyE3bm3uVUtrgxojx7Xja0tiDR7E5fmlTN9YM="

  callback_ids = [
    "blast",
    "test"
  ]

  event_types = [
    "channel_rename",
    "group_rename",
    "member_joined_channel",
    "member_left_channel",
    "test"
  ]
}

module "slackbot_sns" {
  source              = "amancevice/slackbot-sns/aws"
  version             = "1.1.3"
  auto_encrypt_token  = false
  kms_key_id          = "${module.socialismbot.kms_key_id}"
  slack_web_api_token = "AQICAHjBa19e4R5qIz6Kx+CVTCK0X24YvSvQn/280b8MKuUc5gE1ik2jD1rXvejRV4dtQqTKAAAAiTCBhgYJKoZIhvcNAQcGoHkwdwIBADByBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDB1sJQaVHpJ9MU3OYAIBEIBFhqpro+Y0ejoAE8R1rov6jnextDLS5PoENDkx0dAecx/X4+ZHMpaKjh3hPG5nDhWeXT9QxZ0ge0Vi7weAMMZ0Wl9W3qXd"
}
