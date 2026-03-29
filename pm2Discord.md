Absolutely! You can easily integrate PM2 with Discord to get real-time alerts for errors, restarts, or crashes. The most efficient way to do this is by using a PM2 module that connects directly to a **Discord Webhook**.

Here is the most reliable way to set it up using the `pm2-discord` module.


---

### Step 1: Create a Discord Webhook


1. Open your Discord server and go to the channel where you want the logs.
2. Click the **Gear Icon** (Edit Channel) > **Integrations** > **Webhooks**.
3. Click **New Webhook**, name it (e.g., "PM2 Monitor"), and click **Copy Webhook URL**.

### Step 2: Install the PM2 Module

In your terminal, run the following command to install the bridge module:

```bash
pm2 install pm2-discord
```

### Step 3: Configure the Webhook URL

Paste the URL you copied from Discord into this command:

```bash
pm2 set pm2-discord:discord_url https://discord.com/api/webhooks/your_webhook_url
```

### Step 4: Choose What to Monitor

By default, some modules only send "process started" or "process stopped" alerts. To ensure you get **Error logs**, you need to enable them:

* **To get error logs:**

  ```bash
  pm2 set pm2-discord:error true
  ```
* **To get standard logs (Optional - can be spammy):**

  ```bash
  pm2 set pm2-discord:log true
  ```
* **To get crash/restart alerts (Highly recommended):**

  ```bash
  pm2 set pm2-discord:restart true
  ```


---

### Alternative: `pm2-discord-plus`

If you want more "stylish" embeds (colored messages for errors vs. info) or want to filter logs so only specific apps send alerts, I recommend **pm2-discord-plus**:


1. **Install:** `pm2 install JamesNZL/pm2-discord-plus`
2. **Set URL:** `pm2 set pm2-discord-plus:discord_url <YOUR_WEBHOOK_URL>`
3. **Filter by App:** If you only want errors from one specific app:
   `pm2 set pm2-discord-plus:process_name my-api-name`

### Quick Troubleshooting

* **No messages?** Check if your server has outgoing internet access (firewall).
* **Too many messages?** Discord has a rate limit. If your app is throwing 100 errors a second, Discord will block the webhook temporarily. Use `pm2 set pm2-discord:buffer_seconds 5` to group messages together.

**Would you like me to show you how to set up a custom script to send only specific "Critical" errors instead of every log?**

---

### How to stop PM2 Discord logs

You can either temporarily disable alerts or remove the integration entirely.

- Temporary: disable specific alerts (no uninstall)

```bash
# Disable error, restart and standard log notifications
pm2 set pm2-discord:error false
pm2 set pm2-discord:restart false
pm2 set pm2-discord:log false

# Restart the module to apply changes
pm2 restart pm2-discord
```

- Quick off: remove the webhook URL (safe temporary stop)

```bash
pm2 set pm2-discord:discord_url ""
pm2 restart pm2-discord
```

- Permanent: uninstall the PM2 module

```bash
pm2 uninstall pm2-discord
```

- Notes and checks

```bash
# See installed modules / processes
pm2 list

# Inspect current pm2-discord settings
pm2 get pm2-discord:discord_url
pm2 get pm2-discord:error
pm2 get pm2-discord:restart
```

If you used `pm2-discord-plus` instead, replace `pm2-discord` with `pm2-discord-plus` in the commands above.