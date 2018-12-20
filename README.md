# Socialismbot

Terraform configuration for a Socialist Slackbot's back end.

## Architecture

The archetecture for the Slackbot API is fairly straightforward. All requests are routed asynchronously to to SNS. By convention, payloads are routed to topics corresponding to the specific event. Eg, `slack_event_<event_type>`, `slack_callback_<callback_id>`, or `slack_slash_<command>`.

OAuth requests are authenticated using the Slack client and redirected to the configured redirect URL.

<img src="https://github.com/amancevice/terraform-aws-slackbot/blob/master/docs/images/arch.png?raw=true"></img>

## Quickstart

Fork & clone this repository, then create a file called `terraform.tfvars`. Use the following as a template:

```terraform
aws_access_key_id        = "<aws-access-key-id>"
aws_secret_access_key    = "<aws-secret-access-key>"
aws_region               = "<aws-region>"
slack_verification_token = "<slack-verification-token>"
```

This file contains sensitive info so keep it safe!

Next, initialize the terraform project:

```bash
terraform init
```

Finally, review & apply the configuration:

```bash
terraform apply
```

## Configuration Explained

What does it all mean?

### Provider

The provider configures your connection to AWS, including the region to which your infrastructure will be applied. We use variables to hide the sensitive information from being made public.

```terraform
provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
}
```

### Slackbot

The actual code is deployed as a terraform module. The module is quite configurable, but a very basic setup will do the trick.

```terraform
module "socialismbot" {
  source                   = "amancevice/slackbot/aws"
  api_name                 = "socialismbot"
  slack_verification_token = "<verification-token>"
  # auto_encrypt_token       = false

  callback_ids = [
    # ...
  ]

  event_types = [
    # ...
  ]
}
```

It's important your verification token is kept secret, so the module will encrypt it for you unless you specifically tell it not to. Once it's encrypted you may replace the raw token with the encrypted one and set `auto_encrypt_token = false`.

This will create an API with the following endpoints to be configured in Slack:

- `/v1/callbacks` The request URL for interactive components
- `/v1/events` The request URL for Slack events

For every callback you plan on making (these are all custom values), add the callback ID to the `callback_id` list.

Similarly, for every event you wish to listen for, add the [event type](https://api.slack.com/events) to the `event_types` list.

An SNS topic is automatically created for every callback and event. Both the event and callback endpoints listen for `POST` requests made by Slack (using the verification token to ensure the request is indeed coming from Slack) simply publish the `POST` payload to the SNS topic to which the request applies.

For example, if Slack sends a `channel_rename` event, the event will be published to the `slack_event_channel_rename` topic. How the event is handled from there is left to the user to decide.

### Slackbot SNS Messenger

To easily send a message to the Slack workspace the `slackbot_sns` was added. Payloads sent to the `slackbot-sns` topic are routed to Slack as a message from `@socialismbot`.

```terraform
module "slackbot_sns" {
  source              = "amancevice/slackbot-sns/aws"
  kms_key_id          = "${module.socialismbot.kms_key_id}"
  slack_web_api_token = "<web-api-token>"
  # auto_encrypt_token  = false
}
```

As above, it's important your Web API token is kept secret, so the module will encrypt it for you unless you specifically tell it not to. Once it's encrypted you may replace the raw token with the encrypted one and set `auto_encrypt_token = false`.

### Backend

Terraform has the option to store the state of your project remotely. This is useful when you want to share outputs from one project with another.

For example, this project will create the base endpoint where any additional `/slash` commands will be configured but to attach the slash command to the base endpoint you will need the output resource ID from this project.

```terraform
terraform {
  backend "s3" {
    bucket = "<your-unique-bucket>"
    key    = "<yourbot>.tfstate"
    region = "<aws-region>"
  }
}
```

_Note: you must have your AWS access keys properly configured for the backend to load correctly._
