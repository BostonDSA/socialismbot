'use strict';
const AWS           = require('aws-sdk');
const moment        = require('moment-timezone');
const { WebClient } = require('@slack/web-api');
const { google }    = require('googleapis');

const FACEBOOK_PAGE_ID            = process.env.FACEBOOK_PAGE_ID;
const GOOGLE_CALENDAR_ID          = process.env.GOOGLE_CALENDAR_ID;
const GOOGLE_SECRET               = process.env.GOOGLE_SECRET;
const SLACK_COLOR                 = process.env.SLACK_COLOR;
const SLACK_SECRET                = process.env.SLACK_SECRET;
const FACEBOOK_SYNC_FUNCTION_NAME = process.env.FACEBOOK_SYNC_FUNCTION_NAME;
const TZ                          = process.env.TZ;

const FACEBOOK_ICON_URL = 'https://en.facebookbrand.com/wp-content/themes/fb-branding/assets/favicons/apple-touch-icon-57x57.png';
const GOOGLE_URL        = `https://calendar.google.com/calendar/r?cid=${Buffer.from(GOOGLE_CALENDAR_ID).toString('base64').replace(/\n|=+$/, '')}`;

const secretsmanager = new AWS.SecretsManager();
const lambda         = new AWS.Lambda();

let slack, calendar;

const getSlack = async (options) => {
  const secret = await secretsmanager.getSecretValue(options).promise();
  slack = new WebClient(JSON.parse(secret.SecretString).SLACK_TOKEN);
  return slack;
};

const getCalendar = async (options) => {
  const secret       = await secretsmanager.getSecretValue(options).promise();
  const service_acct = JSON.parse(secret.SecretString);
  const jwt          = new google.auth.JWT(
    service_acct.client_email,
    null,
    service_acct.private_key,
    ['https://www.googleapis.com/auth/calendar'],
  );
  calendar = google.calendar({version: 'v3', auth: jwt});
  return calendar;
};

const getAttachment = (event) => {
  const title = `<${event.htmlLink}|${event.summary}>`;
  const loc = `https://maps.google.com/maps?q=${encodeURIComponent(event.location)}`;
  if (moment.tz(event.start.dateTime, TZ).isSame(moment.tz(event.end.dateTime, TZ), 'day')) {
    const start = moment.tz(event.start.dateTime, TZ).format('MMM Do [from] h:mma');
    const end   = moment.tz(event.end.dateTime,   TZ).format('h:mma');
    const text  = `${start} to ${end} at <${loc}|${event.location}>`;
    return {
      color:    SLACK_COLOR,
      fallback: event.summary,
      text:     text,
      title:    title,
    };
  } else {
    const start = moment.tz(event.start.dateTime, TZ).format('MMM Do');
    const end   = moment.tz(event.end.dateTime,   TZ).format('MMM Do');
    const text  = `${start} through ${end} at <${loc}|${event.location}>`;
    return {
      color:    SLACK_COLOR,
      fallback: event.summary,
      text:     text,
      title:    title,
    };
  }
};

const actionPost = (payload) => {
  return slack.dialog.open({
    trigger_id: payload.trigger_id,
    dialog: {
      callback_id:  `${payload.callback_id}_post`,
      title:        `Post Today's Events`,
      submit_label: 'Post',
      elements: [
        {
          data_source: 'conversations',
          hint:        'Choose a conversation for events',
          label:       'Conversation',
          name:        'conversation',
          type:        'select',
        },
      ],
    },
  });
};

const actionSync = async (payload) => {
  await lambda.invoke({
    FunctionName: FACEBOOK_SYNC_FUNCTION_NAME,
    Payload:      JSON.stringify({User: payload.user.id}),
  }).promise();
  return slack.chat.postEphemeral({
    channel: payload.channel.id,
    user:    payload.user.id,
    attachments: [
      {
        author_name: 'Google Calendar Sync',
        author_icon: FACEBOOK_ICON_URL,
        text:        `Started syncing events from <https://facebook.com/${FACEBOOK_PAGE_ID}|facebook> to <${GOOGLE_URL}|Google Calendar>`,
        fallback:    'Started syncing events from facebook Google Calendar',
        color:       '#3B5998',
      },
    ],
  });
};

const submitPost = async (payload) => {
  const time      = moment(payload.action_ts * 1000 || +new Date());
  const timeMin   = time.startOf('day').toISOString();
  const timeMax   = time.endOf('day').toISOString();
  const subscribe = {
    color:       SLACK_COLOR,
    title:       'Subscribe to this Calendar!',
    fallback:    'Subscribe to this Calendar!',
    footer:      '<https://github.com/BostonDSA/socialismbot|BostonDSA/socialismbot>',
    footer_icon: 'https://assets-cdn.github.com/favicon.ico',
    mrkdwn_in:   ['text'],
    text:        `_Have you ever missed a Boston DSA event because you didn't hear about it until it was too late? Subscribe to this calendar to receive push notifications about upcoming DSA events sent directly to your mobile device._`,
    actions: [
      {
        type: 'button',
        name: 'subscribe',
        text: 'Subscribe',
        url:  `https://calendars.dsausa.org/${GOOGLE_CALENDAR_ID}`,
      },
    ],
  };
  if (payload.user && payload.user.id) {
    subscribe.footer += ` | Posted by <@${payload.user.id}>`;
  }

  // Get Slack message
  const msg = await calendar.events.list({
    calendarId:   GOOGLE_CALENDAR_ID,
    timeMin:      timeMin,
    timeMax:      timeMax,
    singleEvents: true,
  }).then((res) => {
    return res.data.items;
  }).then((events) => {
    if (events.length === 0) {
      return {
        channel:     payload.submission.conversation,
        text:        'There are no events today',
        attachments: [subscribe],
      };
    } else if (events.length === 1) {
      return {
        channel:     payload.submission.conversation,
        text:        'There is *1* event today',
        attachments: events.map(getAttachment).concat([subscribe]),
      };
    } else {
      return {
        channel:     payload.submission.conversation,
        text:        `There are *${events.length}* events today`,
        attachments: events.map(getAttachment).concat([subscribe]),
      };
    }
  });

  // Post Slack message
  return slack.chat.postMessage(msg);
};

const handle = async (record) => {
  console.log(`MESSAGE ${record.Sns.Message}`);
  const payload = JSON.parse(record.Sns.Message);

  // Handle slash-command + dialog
  if (payload.callback_id === 'events') {
    return Promise.all(payload.actions.map((action) => {
      if (action.value === 'post') {
        return actionPost(payload);
      } else if (action.value === 'sync') {
        return actionSync(payload);
      }
    }));

  // Handle posting events
  } else if (payload.callback_id === 'events_post') {
    return submitPost(payload);
  }
};

exports.handler = async (event) => {
  console.log(`EVENT ${JSON.stringify(event)}`);
  await Promise.resolve(slack || getSlack({SecretId: SLACK_SECRET}));
  await Promise.resolve(calendar || getCalendar({SecretId: GOOGLE_SECRET}));
  return await Promise.all(event.Records.map(handle));
};
