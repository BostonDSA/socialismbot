variable "aws_access_key_id" {
  description = "AWS Access Key ID."
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key."
  default     = ""
}

variable "aws_profile" {
  description = "AWS Profile."
  default     = ""
}

variable "aws_region" {
  description = "AWS Region."
  default     = "us-east-1"
}

variable "events_google_calendar_id" {
  description = "Google Calendar ID."
  default     = "u21m8kt8bb1lflp8jpmd317iik@group.calendar.google.com"
}

variable "release" {
  description = "Release tag."
}

variable "repo" {
  description = "Project repository."
  default     = "https://github.com/BostonDSA/socialismbot.git"
}

