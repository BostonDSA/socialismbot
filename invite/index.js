'use strict';
const AWS            = require('aws-sdk');
const qs             = require('querystring');
const request        = require('request-promise');
const SecretsManager = new AWS.SecretsManager();
const SLACK_SECRET   = process.env.SLACK_SECRET;
const ENDPOINT       = 'https://slack.com/api/users.admin.invite';

let env;

function getEnv() {
  if (env) {
    return Promise.resolve(env);
  } else {
    return SecretsManager.getSecretValue({
      SecretId: SLACK_SECRET
    }).promise().then((data) => {
      env = JSON.parse(data.SecretString);
      return env;
    })
  }
}

function invite(options) {
  return getEnv().then((env) => {
    return request({
      json:   true,
      method: 'GET',
      qs:     {email: options.email, token: env.LEGACY_TOKEN},
      uri:    ENDPOINT,
    });
  }).then((res) => {
    console.log(`RESPONSE ${JSON.stringify(res)}`);
    if (res.ok === true) {
      options.response.attachments[1].actions = [];
      options.response.attachments[1].text    = `Request accepted by <@${options.user.id}>`;
    } else {
      options.response.attachments[1].text = `:boom: Uh oh, something went wrong: \`${res.error}\` :boom:`;
    }
    return request({
      body:   options.response,
      json:   true,
      method: 'POST',
      uri:    options.response_url,
    });
  });
}

function dismiss(options) {
  options.response.attachments[1].text = `Request rejected by <@${options.user.id}>`;
  return request({
    body:   options.response,
    json:   true,
    method: 'POST',
    uri:    options.response_url,
  });
}

function handler(event, context, callback) {
  console.log(`EVENT ${JSON.stringify(event)}`);
  var message, options;
  return Promise.all(event.Records.map((record) => {
    message = JSON.parse(Buffer.from(record.Sns.Message, 'base64').toString());
    console.log(`MESSAGE ${JSON.stringify(message)}`);
    return Promise.all(message.actions.map((action) => {
      options = {
        email:        action.value,
        response:     message.original_message,
        response_url: message.response_url,
        user:         message.user,
      };
      if (action.name === 'invite') {
        return invite(options);
      } else {
        return dismiss(options);
      }
    }));
  })).then((res) => { callback(null, res); }).catch(callback);
}

exports.handler = handler;
