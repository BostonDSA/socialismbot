const AWS           = require('aws-sdk');
const { WebClient } = require('@slack/client');

const SLACK_SECRET = process.env.SLACK_SECRET;
const WELCOME      = process.env.WELCOME;

const sns            = new AWS.SNS();
const secretsmanager = new AWS.SecretsManager();

let slack;

const getSlack = async () => {
  if (slack === undefined) {
    console.log('FETCH Slack');
    const secret = await secretsmanager.getSecretValue({SecretId: SLACK_SECRET}).promise();
    slack = new WebClient(JSON.parse(secret.SecretString).BOT_TOKEN);
    return slack;
  }
  console.log('CACHED Slack');
  return slack;
};

const welcome = async (record) => {
  await getSlack();
  const payload = JSON.parse(Buffer.from(record.Sns.Message, 'base64').toString());
  const message = JSON.parse(WELCOME);
  const channel = await slack.im.open({user: payload.event.user.id});
  message.channel = channel.channel.id;
  console.log(`POST ${JSON.stringify(message)}`);
  return slack.chat.postMessage(message);
};

exports.handler = async (event) => await Promise.all(event.Records.map(welcome));
