const AWS           = require('aws-sdk');
const { WebClient } = require('@slack/web-api');

const MOD_CHANNEL  = process.env.MOD_CHANNEL;
const SLACK_SECRET = process.env.SLACK_SECRET;

const secretsmanager = new AWS.SecretsManager();

let slack;

const getSlack = async (options) => {
  const secret = await secretsmanager.getSecretValue(options).promise();
  slack = new WebClient(JSON.parse(secret.SecretString).SLACK_TOKEN);
  return slack;
};

const reportMessageAction = async (payload) => {
  const permalink = await slack.chat.getPermalink({
    channel: payload.channel.id,
    message_ts: payload.message.ts
  }).then((res) => res.permalink);
  console.log(`PERMALINK ${permalink}`);

  const dialog = {
    callback_id:  'report_message_submit',
    elements: [
      {
        hint:        'This will be posted to the moderators.',
        label:       'Reason',
        name:        'reason',
        placeholder: 'Why is this thread being reported?',
        type:        'textarea',
      },
    ],
    submit_label: 'Send',
    state:        permalink,
    title:        'Report Message',
  };
  console.log(`DIALOG ${JSON.stringify(dialog)}`);

  return slack.dialog.open({
    trigger_id: payload.trigger_id,
    dialog:     dialog,
  });
};

const reportMessageSubmit = async (payload) => {
  // Post report to mods
  const options = {
    attachments: [
      {
        color:  'warning',
        footer: `Reported by <@${payload.user.id}>`,
        text:   payload.submission.reason,
        ts:     payload.action_ts,
      },
      {
        color:     'danger',
        footer:    `Posted in <#${payload.channel.id}>`,
        mrkdwn_in: ['text'],
        text:      payload.state,
        ts:        payload.action_ts,
      },
    ],
    channel:     MOD_CHANNEL,
    text:        'A message has been reported.',
  };
  console.log(`REPORT ${JSON.stringify(options)}`);
  await slack.chat.postMessage(options);

  // Post receipt to reporter
  return slack.im.open({user: payload.user.id}).then((res) => {
    return res.channel;
  }).then((channel) => {
    const options = {
      attachments: [
        {
          color:  'warning',
          footer: `Reported by <@${payload.user.id}>`,
          text:   payload.submission.reason,
          ts:     payload.action_ts,
        },
      ],
      channel: channel.id,
      text:    'We have received your report.',
    };
    console.log(`DM RECEIPT ${JSON.stringify(options)}`);
    return slack.chat.postMessage(options);
  });
};

const handle = async (record) => {
  console.log(`MESSAGE ${record.Sns.Message}`);
  const payload = JSON.parse(record.Sns.Message);

  // Open dialog to report message
  if (payload.callback_id === 'report_message_action') {
    return reportMessageAction(payload);
  }

  // Post report to moderator channel
  else if (payload.callback_id === 'report_message_submit') {
    return reportMessageSubmit(payload);
  }
};

exports.handler = async (event) => {
  console.log(`EVENT ${JSON.stringify(event)}`);
  await Promise.resolve(slack || getSlack({SecretId: SLACK_SECRET}));
  return await Promise.all(event.Records.map(handle));
};
