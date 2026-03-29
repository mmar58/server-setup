# Send Discord messages from a Node.js backend

This short guide shows two common ways to send messages to Discord from a Node.js backend:

- Webhook (simplest, no bot token required)
- Bot using `discord.js` (more features, requires a bot token)

Prerequisites

- A Discord webhook URL (for webhook examples). See [pm2Discord.md](pm2Discord.md) for webhook setup.
- If using a bot: a bot token and the channel ID to send messages to.
- Node 18+ (has global `fetch`) or install `node-fetch` for older Node versions.

1) Using a Webhook (recommended for simple notifications)

- Install (optional for Node <18):

```bash
npm install node-fetch@3
```

- Minimal example (Node 18+ or with `node-fetch`):

```js
// sendWebhook.js
import fetch from 'node-fetch'; // omit if using Node 18+

const webhookUrl = process.env.DISCORD_WEBHOOK_URL; // store secrets in env

async function sendMessage(content) {
  const payload = { content };
  const res = await fetch(webhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!res.ok) throw new Error(`Discord webhook error: ${res.status}`);
}

// usage example
sendMessage('Hello from Node backend!').catch(console.error);
```

- Webhook payload extras (username, avatar, embeds):

```js
const payload = {
  username: 'Notifier',
  avatar_url: 'https://example.com/avatar.png',
  content: 'Plain text message',
  embeds: [ { title: 'Alert', description: 'Something happened', color: 16711680 } ],
};
```

- Test quickly with `curl`:

```bash
curl -H "Content-Type: application/json" -d '{"content":"test"}' https://discord.com/api/webhooks/XXX/YYY
```

2) Expose an Express endpoint that posts to a webhook

```js
import express from 'express';
import fetch from 'node-fetch'; // optional on Node 18+

const app = express();
app.use(express.json());

app.post('/notify', async (req, res) => {
  const { content } = req.body;
  try {
    await fetch(process.env.DISCORD_WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content }),
    });
    res.sendStatus(204);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to send' });
  }
});

app.listen(3000);
```

3) Using a bot with `discord.js` (for richer capabilities)

- Install:

```bash
npm install discord.js
```

- Send message to a channel by ID:

```js
import { Client, GatewayIntentBits } from 'discord.js';

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once('ready', () => console.log('Bot ready'));

await client.login(process.env.DISCORD_BOT_TOKEN);

const channel = await client.channels.fetch(process.env.DISCORD_CHANNEL_ID);
channel.send('Hello from bot');
```

- Bot notes:
- Bot must be invited to the server with `Send Messages` permission for the target channel.
- Use `channel.send({ embeds: [...] })` to send rich embeds.

4) Useful tips

- Rate limiting: always handle rate limits. Webhooks and bots are rate-limited by Discord; batch or buffer high-frequency events.
- Mentions: to mention a user in a webhook message use `<@USER_ID>` in the `content`.
- Secrets: store `DISCORD_WEBHOOK_URL`, `DISCORD_BOT_TOKEN`, and `DISCORD_CHANNEL_ID` in environment variables or a secrets store.
- Error handling: check the HTTP response from webhook requests and log failures for retries.

5) Quick checklist / commands

```bash
# init project
npm init -y
npm install express node-fetch discord.js

# run (Node 18+ with ESM)
NODE_ENV=production DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/XXX/YYY" node sendWebhook.js
```

If you want, I can add a complete runnable example repository (package.json + small server) and a small test harness to exercise both webhook and bot flows.
