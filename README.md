# Socialismbot

Terraform configuration for a Socialist Slackbot's back end.

This repo is configured to [deploy automatically](./.travis.yml) on tagged releases.

## Architecture

The archetecture for the Socialismbot API is fairly straightforward. All requests are routed to an SNS topic, `slack-socialismbot`, to be processed asynchronously. The messages are posted with attributes that help SNS route the message to the proper subscribers. The `type` attribute defines what kind of Slack message it is (`event`, `callback`, `slash` command, etc), while the `id` attribute identifies the message in the context of the type.

For example a message with attributes

```javascript
{
  "id": "events",
  "type": "slash"
}
```

indicates that the message is a user-initated slash command `/events`.

<img alt="arch" src="https://github.com/amancevice/slackend/blob/master/docs/aws.png?raw=true"/>

## Modules

Each component of the Slackbot is modular so that features can be added or removed more easily.

### Core

The core of the app resides in the first module, named `socialismbot`. This module creates the API Gateway and Lambda resourced needed to communicate with Slack. The core is designed to be agnostic to the features you add and will attempt to handle any callback, events, or slash commands it receives, whether they exist or not.

Because we've configured the `base_url` of the module above to `/slack`, our Slack endpoints will be:

- `/slack/callbacks`
- `/slack/events`
- `/slack/slash/:cmd`

When Slack initiates a request to one of these endpoints callback it will send a POST request to the appropriate endpoint. The app will then forward the request body to the `slack-socialismbot` SNS topic.

For callbacks, the `callback_id` value of the POST body will determine the message attribute `id`:

```javascript
{
  "type": "callback",
  "id": "<callback-id>"
}
```

For events, the [`event_type`](https://api.slack.com/events) value of the POST body will determine the message attribute `id`:

```javascript
{
  "type": "event",
  "id": "<event-type>"
}
```

For slash commands, the name of the slash command ( ie, the [`cmd`] value of the POST body) will determine the message attribute `id`:

```javascript
{
  "type": "slash",
  "id": "<cmd-name>"
}
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
