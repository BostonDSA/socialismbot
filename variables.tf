// AWS
variable "aws_access_key_id" {
  description = "AWS Access Key ID."
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key."
}

variable "aws_region" {
  description = "AWS Region Name."
}

// Google Cloud
variable "client_secret" {
  description = "Google Cloud client secret JSON."
  default     = "client_secret.json"
}

variable "project" {
  description = "The ID of the project to apply any resources to."
}

variable "region" {
  description = "The region to operate under, if not specified by a given resource."
  default     = "us-central1"
}

variable "service_account" {
  description = "An email address that represents a service account. For example, my-other-app@appspot.gserviceaccount.com."
}

// Slack
variable "verification_token" {
  description = "Slack verification token."
}

variable "web_api_token" {
  description = "Slack Web API token."
}

// App
variable "bucket_name" {
  description = "Cloud Storage bucket for storing Cloud Function code archives."
}

variable "bucket_storage_class" {
  description = "Bucket storage class."
  default     = "MULTI_REGIONAL"
}

// Events
variable "events_bucket_prefix" {
  description = "Prefix for Cloud Storage bucket."
  default     = ""
}

variable "events_event_types" {
  description = "Pub/Sub topic names for handing events."
  type        = "list"
  default     = []
}

variable "events_function_name" {
  description = "Cloud Function Name."
  default     = "slack-events"
}

variable "events_memory" {
  description = "Cloud Function Memory."
  default     = 2048
}

variable "events_timeout" {
  description = "Cloud Function Timeout."
  default     = 10
}

// Interactive Components
variable "interactive_components_bucket_prefix" {
  description = "Prefix for Cloud Storage bucket."
  default     = ""
}

variable "interactive_components_callback_ids" {
  description = "List of Pub/Sub topic names to create."
  type        = "list"
  default     = []
}

variable "interactive_components_function_name" {
  description = "Cloud Function Name."
  default     = "slack-interactive-components"
}

variable "interactive_components_memory" {
  description = "Cloud Function Memory."
  default     = 2048
}

variable "interactive_components_timeout" {
  description = "Cloud Function Timeout."
  default     = 10
}

// Chapter SMS
variable "chapter_sms_bucket_prefix" {
  description = "Prefix for Cloud Storage bucket."
  default     = ""
}

variable "chapter_sms_callback_id" {
  description = "Callback ID of interactive component"
  default     = "chapter_sms"
}

variable "chapter_sms_dialog_element_hint" {
  description = "Dialog textarea hint."
  default     = "This will send a text to the entire chapter."
}

variable "chapter_sms_dialog_element_label" {
  description = "Dialog textarea label."
  default     = "Message"
}

variable "chapter_sms_dialog_element_max_length" {
  description = "Dialog textarea max characters."
  default     = 140
}

variable "chapter_sms_dialog_title" {
  description = "Dialog title."
  default     = "Chapter SMS"
}

variable "chapter_sms_group_sms_default_sender_id" {
  description = "A custom ID, such as your business brand, displayed as the sender on the receiving device. Support for sender IDs varies by country."
  default     = ""
}

variable "chapter_sms_group_sms_default_sms_type" {
  description = "Promotional messages are noncritical, such as marketing messages. Transactional messages are delivered with higher reliability to support customer transactions, such as one-time passcodes."
  default     = "Promotional"
}

variable "chapter_sms_group_sms_delivery_status_iam_role_arn" {
  description = "The IAM role that allows Amazon SNS to write logs for SMS deliveries in CloudWatch Logs."
  default     = ""
}

variable "chapter_sms_group_sms_delivery_status_success_sampling_rate" {
  description = "Default percentage of success to sample."
  default     = ""
}

variable "chapter_sms_group_sms_monthly_spend_limit" {
  description = "The maximum amount to spend on SMS messages each month. If you send a message that exceeds your limit, Amazon SNS stops sending messages within minutes."
  default     = ""
}

variable "chapter_sms_group_sms_subscriptions" {
  description = "List of telephone numbers to subscribe to SNS."
  type        = "list"
  default     = []
}

variable "chapter_sms_group_sms_topic_display_name" {
  description = "Display name of the AWS SNS topic."
}

variable "chapter_sms_group_sms_topic_name" {
  description = "Name of the AWS SNS topic."
}

variable "chapter_sms_group_sms_usage_report_s3_bucket" {
  description = "The Amazon S3 bucket to receive daily SMS usage reports. The bucket policy must grant write access to Amazon SNS."
  default     = ""
}

variable "chapter_sms_slash_command_auth_channels_exclude" {
  description = "Optional list of Slack channel IDs to blacklist."
  type        = "list"
  default     = []
}

variable "chapter_sms_slash_command_auth_channels_include" {
  description = "Optional list of Slack channel IDs to whitelist."
  type        = "list"
  default     = []
}

variable "chapter_sms_slash_command_auth_channels_permission_denied" {
  description = "Permission denied message for channels."
  type        = "map"

  default {
    text = "Sorry, you can't do that in this channel."
  }
}

variable "chapter_sms_slash_command_auth_users_exclude" {
  description = "Optional list of Slack user IDs to blacklist."
  type        = "list"
  default     = []
}

variable "chapter_sms_slash_command_auth_users_include" {
  description = "Optional list of Slack user IDs to whitelist."
  type        = "list"
  default     = []
}

variable "chapter_sms_slash_command_auth_users_permission_denied" {
  description = "Permission denied message for users."
  type        = "map"

  default {
    text = "Sorry, you don't have permission to do that."
  }
}

variable "chapter_sms_slash_command_function_name" {
  description = "Cloud Function Name."
  default     = "slack-sms-slash-command"
}

variable "chapter_sms_slash_command_memory" {
  description = "Memory for Cloud Function."
  default     = 2048
}

variable "chapter_sms_slash_command_response" {
  description = "Timeout in seconds for Slack event listener."
  type        = "map"
  default {
    callback_id  = "chapter_sms"
    submit_label = "Send"
    title        = "Chapter SMS"
    elements     = [
      {
        hint       = "This will send a text to the whole chapter."
        label      = "Message"
        max_length = "140"
        name       = "chapter_sms"
        type       = "textarea"
      }
    ]
  }
}

variable "chapter_sms_slash_command_response_type" {
  description = "Response type of command."
  default     = "dialog"
}

variable "chapter_sms_slash_command_timeout" {
  description = "Timeout in seconds for Cloud Function."
  default     = 10
}

variable "chapter_sms_sms_function_name" {
  description = "Cloud Function for publishing events from Slack to Pub/Sub."
  default     = "slack-sms"
}

variable "chapter_sms_sms_memory" {
  description = "Memory for Cloud Function."
  default     = 2048
}

variable "chapter_sms_sms_timeout" {
  description = "Timeout in seconds for Cloud Function."
  default     = 60
}
