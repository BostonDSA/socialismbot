# Socialismbot

Terraform configuration for a Socialist Slackbot's back end.

This repo is configured to [deploy automatically](./.travis.yml) on tagged releases.

## Architecture

The archetecture for the Slackbot API is fairly straightforward. All requests are routed asynchronously to to SNS. By convention, payloads are routed to topics corresponding to the specific event:

- `slack_<your_bot>_event_<event_type>`
- `slack_<your_bot>_callback_<callback_id>`
- `slack_<your_bot>_slash_<command>`.

OAuth requests are authenticated using the Slack client and redirected to the configured redirect URL.

<img alt="arch" src="https://github.com/amancevice/terraform-aws-slackbot/blob/master/docs/images/arch.png?raw=true"/>

## Modules

Each component of the Slackbot is modular so that features can be added or removed more easily.

### Core

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

### Events

The `events` module is responsible for posting a daily digest of events to the [#events](https://bostondsa.slack.com/messages/C7F7Z0WJG) channel each day.

In addition a `/events` slash command is implemented to post events to arbitrary Slack conversations.

### Mods

The `mods` module implements the feature that allows users to report messages to the locked moderator channel.

Reporting a message is possible by selecting the overflow menu for a message and choosing the _Report message_ option.

## Adding Features

```hcl
module my_feature {
  source = "./my-feature"
}
```

Added a features should be contained within their own feature directory under the root and added to the `main.tf` root file as a module (see above). Outputs from the core module can be passed into the feature module as input variables.

If your feature is invoked by a callback, event, or slash command you **must** create the appropriate SNS topic in your module, along with any required subscriptions and permissions.
