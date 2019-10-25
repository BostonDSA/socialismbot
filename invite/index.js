'use strict';
const AWS     = require('aws-sdk');
const qs      = require('querystring');
const request = require('request-promise');

const ENDPOINT     = 'https://slack.com/api/users.admin.invite';
const SLACK_SECRET = process.env.SLACK_SECRET;

const secretsmanager = new AWS.SecretsManager();

let token;

const getToken = async (options) => {
  const secret = await secretsmanager.getSecretValue(options).promise();
  token = JSON.parse(secret.SecretString).SLACK_LEGACY_TOKEN;
  return token;
};

const invite = async (options) => {
  const res = await request({
    json:   true,
    method: 'GET',
    qs:     {email: options.email, token: token},
    uri:    ENDPOINT,
  });
  console.log(`RESPONSE ${JSON.stringify(res)}`);
  if (res.ok === true) {
    options.response.attachments[1].actions = [];
    options.response.attachments[1].text    = `Request accepted by <@${options.user.id}>`;
  }
  else {
    options.response.attachments[1].text = `:boom: Uh oh, something went wrong: \`${res.error}\` :boom:`;
  }
  return request({
    body:   options.response,
    json:   true,
    method: 'POST',
    uri:    options.response_url,
  });
};

const dismiss = async (options) => {
  options.response.attachments[1].text = `Request rejected by <@${options.user.id}>`;
  return request({
    body:   options.response,
    json:   true,
    method: 'POST',
    uri:    options.response_url,
  });
};

const handle = async (record) => {
  console.log(`MESSAGE ${record.Sns.Message}`);
  const payload = JSON.parse(record.Sns.Message);
  return Promise.all(payload.actions.map((action) => {
    const options = {
      email:        action.value,
      response:     payload.original_message,
      response_url: payload.response_url,
      user:         payload.user,
    };
    if (action.name === 'invite') {
      return invite(options);
    } else {
      return dismiss(options);
    }
  }));
};

exports.handler = async (event) => {
  await Promise.resolve(token || getToken({SecretId: SLACK_SECRET}));
  return await Promise.all(event.Records.map(handle));
};
