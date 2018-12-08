const dotenv = require('dotenv')
dotenv.config();
const moment = require('moment-timezone');

const calendarId = process.env.GOOGLE_CALENDAR_ID;
const color = process.env.COLOR;
const help_url = process.env.HELP_URL;
const secret = process.env.AWS_SECRET;
const topic = process.env.TOPIC_ARN;

let calendar, payload, secrets;

var gcal = {
  info: (options) => {
    return calendar.calendars.get(options).then((res) => {
      console.log(`CALENDAR ${JSON.stringify(res.data)}`);
      return res.data;
    });
  },
  events: (options, events) => {
    return calendar.events.list(options).then((res) => {
      if (!events) {
        events = [];
      }
      events = events.concat(res.data.items);
      if (res.data.nextPageToken === undefined) {
        console.log(`EVENT COUNT ${events.length}`);
        return events;
      }
      options.pageToken = res.data.nextPageToken;
      return gcal.events(options, events);
    });
  }
};

/**
 * Get Slack tokens from memory or AWS SecretsManager.
 */
function getSecrets() {
  return new Promise((resolve, reject) => {
    if (secrets) {
      resolve(secrets);
    } else {
      console.log(`FETCH ${secret}`);
      const AWS = require('aws-sdk');
      const secretsmanager = new AWS.SecretsManager();
      secretsmanager.getSecretValue({SecretId: secret}, (err, data) => {
        if (err) {
          reject(err);
        } else {
          secrets = JSON.parse(data.SecretString);
          console.log(`RECEIVED ${secret}`);
          resolve(secrets);
        }
      });
    }
  });
}

/**
 * Get Google Calendar API Client.
 */
function getGoogleCalendar(service) {
  return new Promise((resolve, reject) => {
    if (calendar) {
      resolve(calendar);
    } else {
      const { google } = require('googleapis');
      const jwt = new google.auth.JWT(
        service.client_email,
        null,
        service.private_key,
        ['https://www.googleapis.com/auth/calendar']
      );
      calendar = google.calendar({version: 'v3', auth: jwt});
      resolve(calendar);
    }
  });
}

/**
 * Get payload from SNS message.
 *
 * @param {object} event SNS event object.
 */
function getPayload(event) {
  return new Promise((resolve, reject) => {
    event.Records.map((record) => {
      payload = JSON.parse(Buffer.from(record.Sns.Message, 'base64'));
      console.log(`PAYLOAD ${JSON.stringify(payload)}`);
      resolve(payload);
    });
  });
}

/**
 * Get calendar events.
 *
 * @param {object} payload Payload for filtering events.
 */
function getEvents(payload) {
  const ts = payload.action_ts * 1000 || +new Date();
  const tz = payload.tz;
  const time = moment.tz(ts, tz);
  const timeMin = time.startOf('day').toISOString();
  const timeMax = time.endOf('day').toISOString();
  return gcal.events({
    calendarId: calendarId,
    timeMin: timeMin,
    timeMax: timeMax,
    singleEvents: true,
  });
}

/**
 * Transform event into Slack message attachment.
 *
 * @param {object} event Google Calendar event.
 */
function getAttachment(options) {
  console.log(`EVENT ${JSON.stringify(options)}`);
  const event = options.event;
  const tz = options.tz;
  const title = `<${event.htmlLink}|${event.summary}>`;
  const loc = `https://maps.google.com/maps?q=${encodeURIComponent(event.location)}`;
  if (moment.tz(event.start.dateTime, tz).isSame(moment.tz(event.end.dateTime, tz), 'day')) {
    const start = moment.tz(event.start.dateTime, tz).format('MMM Do [from] h:mma');
    const end = moment.tz(event.end.dateTime, tz).format('h:mma');
    const text = `${start} to ${end} at <${loc}|${event.location}>`;
    return {
      color: color,
      fallback: event.summary,
      text: text,
      title: title
    };
  } else {
    const start = moment.tz(event.start.dateTime, tz).format('MMM Do');
    const end = moment.tz(event.end.dateTime, tz).format('MMM Do');
    const text = `${start} through ${end} at <${loc}|${event.location}>`;
    return {
      color: color,
      fallback: event.summary,
      text: text,
      title: title
    };
  }
}

/**
 * Get Slack message.
 *
 * @param {string} channel Slack channel ID.
 * @param {string} cid Google Calendar ID.
 * @param {array} list Google Calendar events list.
 */
function getMessage(options) {
  const subscribe = getSubscriptions(options);
  const channel = options.channel;
  const events = options.events || [];
  const tz = options.tz;

  if (events.length === 0) {
    return {
      channel: channel,
      text: 'There are no events today',
      attachments: [subscribe]
    };
  }

  else if (events.length === 1) {
    return {
      channel: channel,
      text: 'There is *1* event today',
      attachments: events.map(x => {
        return getAttachment({event: x, tz: tz});
      }).concat([subscribe])
    };
  }

  else {
    return {
      channel: channel,
      text: `There are *${events.length}* events today`,
      attachments: events.map(x => {
        return getAttachment({event: x, tz: tz});
      }).concat([subscribe])
    };
  }
}

/**
 * Get subscription attachment for Slack message.
 *
 * @param {string} cid Google Calendar ID.
 */
function getSubscriptions(options) {
  const id = options.id;
  const cid = Buffer.from(id).toString('base64').replace(/\n|=+$/, '');
  const google_url = `https://calendar.google.com/calendar/r?cid=${cid}`;
  const webcal_url = `webcal://calendar.google.com/calendar/ical/${encodeURIComponent(id)}/public/basic.ics`;
  const subscribe = {
    color: color,
    title: 'Subscribe to this Calendar!',
    fallback: 'Subscribe to this Calendar!',
    footer: '<https://github.com/BostonDSA/socialismbot|BostonDSA/socialismbot>',
    footer_icon: 'https://assets-cdn.github.com/favicon.ico',
    mrkdwn_in: ['text'],
    text: `Choose _\u2039\u2039 Google \u203a\u203a_ if you already use Google Calendar\nChoose _\u2039\u2039 iCalendar \u203a\u203a_ if you use something else\n_Subscribing via the \u2039\u2039 Google \u203a\u203a button will only work from a computer!_`,
    actions: [
      {
        type: 'button',
        name: 'google',
        text: 'Google',
        url: google_url
      },
      {
        type: 'button',
        name: 'icalendar',
        text: 'iCalendar',
        url: webcal_url
      },
      {
        type: 'button',
        name: 'not_sure',
        text: "I'm not sure",
        url: help_url
      }
    ]
  };
  return subscribe;
}

/**
 * Publish message to Slack.
 *
 * @param {object} message Slack message object.
 */
function publishMessage(message) {
  const AWS = require('aws-sdk');
  const SNS = new AWS.SNS();
  return new Promise((resolve, reject) => {
    SNS.publish({
      Message: JSON.stringify(message),
      TopicArn: topic
    }, (err, data) => {
      if (err) {
        reject(err);
      } else {
        resolve(data);
      }
    });
  });
}

/**
 * Handle SNS message.
 *
 * @param {object} event SNS event object.
 * @param {object} context SNS event context.
 * @param {function} callback Lambda callback function.
 */
function handler(event, context, callback) {
  console.log(`EVENT ${JSON.stringify(event)}`);
  return getPayload(event).then(getSecrets).then(getGoogleCalendar).then(() => {
    return gcal.info({calendarId: calendarId}).then((info) => {
      payload.tz = info.timeZone;
      return getEvents(payload).then((events) => {
        return getMessage({
          channel: payload.submission.conversation,
          events: events,
          id: info.id,
          tz: info.timeZone
        });
      });
    });
  }).then((res) => {
    console.log(`MESSAGE ${JSON.stringify(res)}`);
    publishMessage(res);
  }).then((res) => {
    callback();
  }).catch((err) => {
    console.error(`ERROR ${err}`);
    callback(err);
  });
}

exports.handler = handler;
