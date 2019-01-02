# Socialismbot

Terraform configuration for a Socialist Slackbot's back end.

## Architecture

The archetecture for the Slackbot API is fairly straightforward. All requests are routed asynchronously to to SNS. By convention, payloads are routed to topics corresponding to the specific event:

- `slack_<your_bot>_event_<event_type>`
- `slack_<your_bot>_callback_<callback_id>`
- `slack_<your_bot>_slash_<command>`.

OAuth requests are authenticated using the Slack client and redirected to the configured redirect URL.

<img alt="arch" src="https://github.com/amancevice/terraform-aws-slackbot/blob/master/docs/images/arch.png?raw=true"/>

## Quickstart

Clone this repository, then copy `terraform.tfvars.example` to `terraform.tfvars`. Fill in the values on the new file. This file can contain sensitive info so keep it safe!

Next, initialize the terraform project:

```bash
terraform init
```

Review any pending changes with:

```bash
terraform plan
```

Finally, apply a new configuration (if necessary):

```bash
terraform apply
```

## Configuration Explained

What does it all mean?

### Provider

```hcl
provider aws {
  version = "~> <x.y>"
  region  = "<aws-region>"
  profile = "<aws-profile>"
}
```

The provider configures your connection to AWS, including the region to which your infrastructure will be applied. Use variables to hide the sensitive information from public view.

It's recommended that you use [Named Profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) instead of access keys to configure your AWS credentials.

In your `~/.aws/credentials` file add a new access profile named `bdsa`:

```ini
[bdsa]
aws_access_key_id = <your-access-key>
aws_secret_access_key = <your-secret-access-key>
```

Next, in your `~/aws/config` file add a new aws profile:

```ini
[profile bdsa]
region = us-east-1
source_profile = bdsa
```

This way you are able to access AWS resources using the profile handle instead of peppering sensitive keys throughout your filesystem in `.env` or `terraform.tfvars` files.

### Backend

```hcl
terraform {
  backend s3 {
    bucket  = "<your-bucket>"
    key     = "<your-bot>.tfstate"
    region  = "<aws-region>"
    profile = "<aws-profile>"
  }
}
```

Terraform has the option to store the state of your project remotely. This is useful when you want to share outputs from one project with another or simpley between developers.

_Note: you must have your AWS access keys properly configured for the backend to load correctly._

### Modules

```hcl
module socialismbot {
  source     = "amancevice/slackbot/aws"
  api_name   = "socialismbot"
  base_url   = "/slack"
  secret_arn = "<secret-arn>"
  kms_key_id = "<kms-key-id>"
}
```

Each component of the Slackbot is modular so that features can be added or removed more easily.

The core of the app resides in the first module, named `socialismbot`. This module creates the API Gateway and Lambda resourced needed to communicate with Slack. The core is designed to be agnostic to the features you add and will attempt to handle any callback, events, or slash commands it receives, whether they exist or not.

Because we've configured the `base_url` of the module above to `/slack`, our Slack endpoints will be:

- `/slack/callbacks`
- `/slack/events`
- `/slack/slash/:cmd`

When Slack initiates a request to one of these endpoints callback it will send a POST request to the appropriate endpoint. The app will then forward the request body to a unique SNS topic for each type of message.

For callbacks, the `callback_id` value of the POST body will determine the topic name:

```
slack_socialismbot_callback_<callback-id>
```

For events, the [`event_type`](https://api.slack.com/events) value of the POST body will determine the topic name:

```
slack_socialismbot_event_<event-type>
```

For slash commands, the name of the slash command ( ie, the [`cmd`] value of the POST body) will determine the topic name:

```
slack_socialismbot_slash_<cmd-name>
```

### Adding Features

```hcl
module my_feature {
  source = "./my-feature"
}
```

Added a features should be contained within their own feature directory under the root and added to the `main.tf` root file as a module (see above). Outputs from the core module can be passed into the feature module as input variables.

If your feature is invoked by a callback, event, or slash command you **must** create the appropriate SNS topic in your module, along with any required subscriptions and permissions.
