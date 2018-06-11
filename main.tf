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

resource "google_storage_bucket" "bucket" {
  name          = "${var.bucket_name}"
  storage_class = "${var.bucket_storage_class}"
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = "${google_storage_bucket.bucket.name}"
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.service_account}"
}

module "events" {
  source             = "amancevice/slack-events/google"
  version            = "0.2.5"
  bucket_name        = "${google_storage_bucket.bucket.name}"
  bucket_prefix      = "${var.events_bucket_prefix}"
  client_secret      = "${file("${var.client_secret}")}"
  event_types        = ["${var.events_event_types}"]
  function_name      = "${var.events_function_name}"
  memory             = "${var.events_memory}"
  project            = "${var.project}"
  timeout            = "${var.events_timeout}"
  verification_token = "${var.verification_token}"
}

module "interactive_components" {
  source             = "amancevice/slack-interactive-components/google"
  version            = "0.3.2"
  bucket_name        = "${google_storage_bucket.bucket.name}"
  bucket_prefix      = "${var.interactive_components_bucket_prefix}"
  callback_ids       = ["${var.interactive_components_callback_ids}"]
  client_secret      = "${file("${var.client_secret}")}"
  function_name      = "${var.interactive_components_function_name}"
  memory             = "${var.interactive_components_memory}"
  project            = "${var.project}"
  timeout            = "${var.interactive_components_timeout}"
  verification_token = "${var.verification_token}"
}

module "chapter_sms" {
  source                                          = "amancevice/slack-sms/google"
  version                                         = "0.2.4"
  aws_access_key_id                               = "${var.aws_access_key_id}"
  aws_region                                      = "${var.aws_region}"
  aws_secret_access_key                           = "${var.aws_secret_access_key}"
  bucket_name                                     = "${google_storage_bucket.bucket.name}"
  bucket_prefix                                   = "${var.chapter_sms_bucket_prefix}"
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
