const AWS           = require('aws-sdk');
const { WebClient } = require('@slack/client');

const SLACK_SECRET = process.env.SLACK_SECRET;
const WELCOME      = process.env.WELCOME;

const sns            = new AWS.SNS();
const secretsmanager = new AWS.SecretsManager();

let slack;

const getSlack = async (options) => {
  const secret = await secretsmanager.getSecretValue(options).promise();
  slack = new WebClient(JSON.parse(secret.SecretString).SLACK_TOKEN);
  return slack;
};

const handle = async (record) => {
  const payload = JSON.parse(record.Sns.Message);
  const message = JSON.parse(WELCOME);
  const channel = await slack.im.open({user: payload.event.user.id});
  message.channel = channel.channel.id;
  return slack.chat.postMessage(message);
};

exports.handler = async (event) => {
  console.log(`EVENT ${JSON.stringify(event)}`);
  await Promise.resolve(slack || getSlack({SecretId: SLACK_SECRET}));
  return await Promise.all(event.Records.map(handle));
};
