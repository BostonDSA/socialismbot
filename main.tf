provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
  version    = "~> 1.22"
}

provider "google" {
  credentials = "${file("${var.client_secret}")}"
  project     = "${var.project}"
  region      = "${var.region}"
  version     = "~> 1.14"
}

data "google_client_config" "cloud" {
}

resource "google_storage_bucket" "bucket" {
  name          = "${var.bucket_name}"
  storage_class = "${var.bucket_storage_class}"
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = "${google_storage_bucket.bucket.name}"
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.service_account}"
}

resource "google_kms_key_ring" "socialismbot" {
  location = "global"
  name     = "socialismbot"
  project  = "${data.google_client_config.cloud.project}"
}

resource "google_kms_crypto_key" "socialismbot" {
  key_ring        = "${google_kms_key_ring.socialismbot.id}"
  name            = "socialismbot"
  rotation_period = "7776000s"
}

module "events" {
  source             = "amancevice/slack-events/google"
  version            = "0.5.0"
  bucket_name        = "${google_storage_bucket.bucket.name}"
  event_types        = ["${var.events_event_types}"]
  function_name      = "${var.events_function_name}"
  memory             = "${var.events_memory}"
  timeout            = "${var.events_timeout}"
  verification_token = "${var.verification_token}"
}

module "interactive_components" {
  source             = "amancevice/slack-interactive-components/google"
  version            = "0.6.0"
  bucket_name        = "${google_storage_bucket.bucket.name}"
  callback_ids       = ["${var.interactive_components_callback_ids}"]
  function_name      = "${var.interactive_components_function_name}"
  memory             = "${var.interactive_components_memory}"
  timeout            = "${var.interactive_components_timeout}"
  verification_token = "${var.verification_token}"
}

module "chapter_sms" {
  source                                          = "amancevice/slack-sms/google"
  version                                         = "0.5.1"
  aws_access_key_id                               = "${var.aws_access_key_id}"
  aws_region                                      = "${var.aws_region}"
  aws_secret_access_key                           = "${var.aws_secret_access_key}"
  bucket_name                                     = "${google_storage_bucket.bucket.name}"
  callback_id                                     = "${var.chapter_sms_callback_id}"
  dialog_element_hint                             = "${var.chapter_sms_dialog_element_hint}"
  dialog_element_label                            = "${var.chapter_sms_dialog_element_label}"
  dialog_element_max_length                       = "${var.chapter_sms_dialog_element_max_length}"
  dialog_title                                    = "${var.chapter_sms_dialog_title}"

  group_sms_default_sender_id                     = "${var.chapter_sms_group_sms_default_sender_id}"
  group_sms_default_sms_type                      = "${var.chapter_sms_group_sms_default_sms_type}"
  group_sms_delivery_status_iam_role_arn          = "${var.chapter_sms_group_sms_delivery_status_iam_role_arn}"
  group_sms_delivery_status_success_sampling_rate = "${var.chapter_sms_group_sms_delivery_status_success_sampling_rate}"
  group_sms_monthly_spend_limit                   = "${var.chapter_sms_group_sms_monthly_spend_limit}"
  group_sms_subscriptions                         = ["${var.chapter_sms_group_sms_subscriptions}"]
  group_sms_topic_display_name                    = "${var.chapter_sms_group_sms_topic_display_name}"
  group_sms_topic_name                            = "${var.chapter_sms_group_sms_topic_name}"
  group_sms_usage_report_s3_bucket                = "${var.chapter_sms_group_sms_usage_report_s3_bucket}"

  slash_command_auth_channels_exclude             = "${var.chapter_sms_slash_command_auth_channels_exclude}"
  slash_command_auth_channels_include             = "${var.chapter_sms_slash_command_auth_channels_include}"
  slash_command_auth_channels_permission_denied   = "${var.chapter_sms_slash_command_auth_channels_permission_denied}"
  slash_command_auth_users_exclude                = "${var.chapter_sms_slash_command_auth_users_exclude}"
  slash_command_auth_users_include                = "${var.chapter_sms_slash_command_auth_users_include}"
  slash_command_auth_users_permission_denied      = "${var.chapter_sms_slash_command_auth_users_permission_denied}"
  slash_command_description                       = "${var.chapter_sms_slash_command_description}"
  slash_command_function_name                     = "${var.chapter_sms_slash_command_function_name}"
  slash_command_labels                            = "${var.chapter_sms_slash_command_labels}"
  slash_command_memory                            = "${var.chapter_sms_slash_command_memory}"
  slash_command_timeout                           = "${var.chapter_sms_slash_command_timeout}"

  sms_description                                 = "${var.chapter_sms_sms_description}"
  sms_function_name                               = "${var.chapter_sms_sms_function_name}"
  sms_labels                                      = "${var.chapter_sms_sms_labels}"
  sms_memory                                      = "${var.chapter_sms_sms_memory}"
  sms_timeout                                     = "${var.chapter_sms_sms_timeout}"

  verification_token                              = "${var.verification_token}"
  web_api_token                                   = "${var.web_api_token}"
}

module "slack_drive" {
  source                              = "amancevice/slack-drive/google"
  version                             = "1.2.2"
  auth_channels_exclude               = "${var.slack_drive_auth_channels_exclude}"
  auth_channels_include               = "${var.slack_drive_auth_channels_include}"
  auth_users_exclude                  = "${var.slack_drive_auth_users_exclude}"
  auth_users_include                  = "${var.slack_drive_auth_users_include}"
  bucket_name                         = "${google_storage_bucket.bucket.name}"
  channel                             = "${var.slack_drive_channel}"
  client_secret                       = "${file("${var.client_secret}")}"
  color                               = "${var.slack_drive_color}"
  project                             = "${var.project}"
  region                              = "${var.region}"
  verification_token                  = "${var.verification_token}"
  web_api_token                       = "${var.web_api_token}"

  channel_rename_description          = "${var.slack_drive_channel_rename_description}"
  channel_rename_function_name        = "${var.slack_drive_channel_rename_function_name}"
  channel_rename_labels               = "${var.slack_drive_channel_rename_labels}"
  channel_rename_memory               = "${var.slack_drive_channel_rename_memory}"
  channel_rename_timeout              = "${var.slack_drive_channel_rename_timeout}"
  channel_rename_trigger_topic        = "${var.slack_drive_channel_rename_trigger_topic}"

  group_rename_description            = "${var.slack_drive_group_rename_description}"
  group_rename_function_name          = "${var.slack_drive_group_rename_function_name}"
  group_rename_labels                 = "${var.slack_drive_group_rename_labels}"
  group_rename_memory                 = "${var.slack_drive_group_rename_memory}"
  group_rename_timeout                = "${var.slack_drive_group_rename_timeout}"
  group_rename_trigger_topic          = "${var.slack_drive_group_rename_trigger_topic}"

  member_joined_channel_description   = "${var.slack_drive_member_joined_channel_description}"
  member_joined_channel_function_name = "${var.slack_drive_member_joined_channel_function_name}"
  member_joined_channel_labels        = "${var.slack_drive_member_joined_channel_labels}"
  member_joined_channel_memory        = "${var.slack_drive_member_joined_channel_memory}"
  member_joined_channel_timeout       = "${var.slack_drive_member_joined_channel_timeout}"
  member_joined_channel_trigger_topic = "${var.slack_drive_member_joined_channel_trigger_topic}"

  member_left_channel_description     = "${var.slack_drive_member_left_channel_description}"
  member_left_channel_function_name   = "${var.slack_drive_member_left_channel_function_name}"
  member_left_channel_labels          = "${var.slack_drive_member_left_channel_labels}"
  member_left_channel_memory          = "${var.slack_drive_member_left_channel_memory}"
  member_left_channel_timeout         = "${var.slack_drive_member_left_channel_timeout}"
  member_left_channel_trigger_topic   = "${var.slack_drive_member_left_channel_trigger_topic}"

  redirect_description                = "${var.slack_drive_redirect_description}"
  redirect_function_name              = "${var.slack_drive_redirect_function_name}"
  redirect_labels                     = "${var.slack_drive_redirect_labels}"
  redirect_memory                     = "${var.slack_drive_redirect_memory}"
  redirect_timeout                    = "${var.slack_drive_redirect_timeout}"

  slash_command                       = "${var.slack_drive_slash_command}"
  slash_command_description           = "${var.slack_drive_slash_command_description}"
  slash_command_function_name         = "${var.slack_drive_slash_command_function_name}"
  slash_command_labels                = "${var.slack_drive_slash_command_labels}"
  slash_command_memory                = "${var.slack_drive_slash_command_memory}"
  slash_command_timeout               = "${var.slack_drive_slash_command_timeout}"
}
