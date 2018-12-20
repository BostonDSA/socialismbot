'use strict';
const AWS = require('aws-sdk');
const moment = require('moment-timezone');
const { WebClient } = require('@slack/client');
const { google } = require('googleapis');
const SecretsManager = new AWS.SecretsManager();
const Lambda = new AWS.Lambda();

const FACEBOOK_ICON_URL = 'https://en.facebookbrand.com/wp-content/themes/fb-branding/assets/favicons/apple-touch-icon-57x57.png';
const FACEBOOK_PAGE_ID = process.env.FACEBOOK_PAGE_ID;
const GOOGLE_CALENDAR_ID = process.env.GOOGLE_CALENDAR_ID;
const GOOGLE_SECRET = process.env.GOOGLE_SECRET;
const SLACK_COLOR = process.env.SLACK_COLOR;
const SLACK_SECRET = process.env.SLACK_SECRET;
const FACEBOOK_SYNC_FUNCTION_NAME = process.env.FACEBOOK_SYNC_FUNCTION_NAME;
const TZ = process.env.TZ;

const GOOGLE_URL = `https://calendar.google.com/calendar/r?cid=${Buffer.from(GOOGLE_CALENDAR_ID).toString('base64').replace(/\n|=+$/, '')}`;

let slack, calendar;

function getSlack() {
  if (slack) {
    return Promise.resolve(slack);
  } else {
    return SecretsManager.getSecretValue({
      SecretId: SLACK_SECRET
    }).promise().then((data) => {
      slack = new WebClient(JSON.parse(data.SecretString).BOT_ACCESS_TOKEN);
      return slack;
    })
  }
}

function getCalendar() {
  if (calendar) {
    return Promise.resolve(calendar);
  } else {
    return SecretsManager.getSecretValue({
      SecretId: GOOGLE_SECRET
    }).promise().then((data) => {
      const service_acct = JSON.parse(data.SecretString);
      const jwt = new google.auth.JWT(
        service_acct.client_email,
        null,
        service_acct.private_key,
        ['https://www.googleapis.com/auth/calendar']
      );
      calendar = google.calendar({version: 'v3', auth: jwt});
      return calendar;
    })
  }
}

function getAttachment(event) {
  const title = `<${event.htmlLink}|${event.summary}>`;
  const loc = `https://maps.google.com/maps?q=${encodeURIComponent(event.location)}`;
  if (moment.tz(event.start.dateTime, TZ).isSame(moment.tz(event.end.dateTime, TZ), 'day')) {
    const start = moment.tz(event.start.dateTime, TZ).format('MMM Do [from] h:mma');
    const end = moment.tz(event.end.dateTime, TZ).format('h:mma');
    const text = `${start} to ${end} at <${loc}|${event.location}>`;
    return {
      color: SLACK_COLOR,
      fallback: event.summary,
      text: text,
      title: title
    };
  } else {
    const start = moment.tz(event.start.dateTime, TZ).format('MMM Do');
    const end = moment.tz(event.end.dateTime, TZ).format('MMM Do');
    const text = `${start} through ${end} at <${loc}|${event.location}>`;
    return {
      color: SLACK_COLOR,
      fallback: event.summary,
      text: text,
      title: title
    };
  }
}

async function actionPost(message) {
  await getSlack();
  await slack.dialog.open({
    trigger_id: message.trigger_id,
    dialog: {
      callback_id: `${message.callback_id}_post`,
      title: `Post Today's Events`,
      submit_label: 'Post',
      elements: [
        {
          data_source: 'conversations',
          hint: 'Choose a conversation for events',
          label: 'Conversation',
          name: 'conversation',
          type: 'select',
        },
      ],
    },
  });
}

async function actionSync(message) {
  await getSlack();
  await Lambda.invoke({
    FunctionName: FACEBOOK_SYNC_FUNCTION_NAME,
    Payload: JSON.stringify({User: message.user.id}),
  }).promise();
  await slack.chat.postEphemeral({
    channel: message.channel.id,
    user: message.user.id,
    attachments: [
      {
        author_name: 'Google Calendar Sync',
        author_icon: FACEBOOK_ICON_URL,
        text: `Started syncing events from <https://facebook.com/${FACEBOOK_PAGE_ID}|facebook> to <${GOOGLE_URL}|Google Calendar>`,
        fallback: 'Started syncing events from facebook Google Calendar',
        color: '#3B5998',
      },
    ],
  });
}

async function submitPost(message) {
  const time = moment(message.action_ts * 1000 || +new Date());
  const timeMin = time.startOf('day').toISOString();
  const timeMax = time.endOf('day').toISOString();
  const subscribe = {
    color: SLACK_COLOR,
    title: 'Subscribe to this Calendar!',
    fallback: 'Subscribe to this Calendar!',
    footer: '<https://github.com/BostonDSA/socialismbot|BostonDSA/socialismbot>',
    footer_icon: 'https://assets-cdn.github.com/favicon.ico',
    mrkdwn_in: ['text'],
    text: `_Have you ever missed a Boston DSA event because you didn't hear about it until it was too late? Subscribe to this calendar to receive push notifications about upcoming DSA events sent directly to your mobile device._`,
    actions: [
      {
        type: 'button',
        name: 'subscribe',
        text: "Subscribe",
        url: `https://calendars.dsausa.org/${GOOGLE_CALENDAR_ID}`,
      },
    ],
  };
  if (message.user !== undefined) {
    subscribe.footer += ` | Posted by <@${message.user.id}>`;
  }
  await getSlack();
  await getCalendar();
  await calendar.events.list({
    calendarId: GOOGLE_CALENDAR_ID,
    timeMin: timeMin,
    timeMax: timeMax,
    singleEvents: true,
  }).then((res) => {
    const events = res.data.items;
    if (events.length === 0) {
      return {
        channel: message.submission.conversation,
        text: 'There are no events today',
        attachments: [subscribe],
      };
    } else if (events.length === 1) {
      return {
        channel: message.submission.conversation,
        text: 'There is *1* event today',
        attachments: events.map(getAttachment).concat([subscribe]),
      };
    } else {
      return {
        channel: message.submission.conversation,
        text: `There are *${events.length}* events today`,
        attachments: events.map(getAttachment).concat([subscribe]),
      };
    }
  }).then((msg) => {
    slack.chat.postMessage(msg);
  });
}

function handler(event, context, callback) {
  console.log(`EVENT ${JSON.stringify(event)}`);
  var message;
  event.Records.map((record) => {
    message = JSON.parse(Buffer.from(record.Sns.Message, 'base64'));
    console.log(`MESSAGE ${JSON.stringify(message)}`);
    if (message.callback_id === 'events') {
      message.actions.map((action) => {
        if (action.value === 'post') {
          actionPost(message).then(callback).catch(callback);
        } else if (action.value === 'sync') {
          actionSync(message).then(callback).catch(callback);
        }
      });
    } else if (message.callback_id === 'events_post') {
      submitPost(message).then(callback).catch(callback);
    }
  });
}

exports.handler = handler;
