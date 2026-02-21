# PM2 Cheat Sheet

PM2 is a production process manager for Node.js applications with a built-in load balancer. It allows you to keep applications alive forever, to reload them without downtime and to facilitate common system admin tasks.

## Installation

### Using NPM
```bash
npm install pm2@latest -g
```

### Using PNPM
```bash
pnpm add -g pm2
```

## Basic Usage

| Command | Description |
| :--- | :--- |
| `pm2 start app.js` | Start an application |
| `pm2 start app.js --name "my-api"` | Start app with a specific name |
| `pm2 stop all` | Stop all processes |
| `pm2 restart all` | Restart all processes |
| `pm2 delete all` | Kill and delete all processes |
| `pm2 list` | List all running processes |
| `pm2 monit` | Monitor memory and CPU |
| `pm2 logs` | View logs for all processes |

## Upgrading PM2

To upgrade PM2 to the latest version:

```bash
# 1. Install latest version
npm install pm2@latest -g
# OR
pnpm add -g pm2

# 2. Update in-memory PM2
pm2 update
```

## Startup Script (Persistence)

To generate and save a startup script so PM2 restarts on server reboot:

```bash
# 1. Generate startup script (copy/paste the output command)
pm2 startup

# 2. Freeze the current process list
pm2 save
```

## Log Configuration via Ecosystem File

The best way to configure PM2 is using an `ecosystem.config.js` file.

**Generate file:**
```bash
pm2 init simple
```

**Configuration Options:**

```javascript
module.exports = {
  apps : [{
    name   : "app1",
    script : "./app.js",
    
    // Logging Configuration
    log_date_format: "YYYY-MM-DD HH:mm:ss", // Add timestamps to logs
    error_file: "./logs/app1-err.log",      // Path for error logs
    out_file: "./logs/app1-out.log",        // Path for output logs
    merge_logs: true,                       // Merge cluster logs into one file
    
    // Log Rotation (if pm2-logrotate is installed)
    max_memory_restart: "300M",
    
    env: {
      NODE_ENV: "development",
    },
    env_production: {
      NODE_ENV: "production",
    }
  }]
}
```

## Applying Environment Variable Changes

When you update `env` values in `ecosystem.config.js`, a plain `pm2 restart` **will not** pick up the new values. You must use the `--update-env` flag:

```bash
# Reload with zero downtime (recommended for production)
pm2 reload ecosystem.config.js --update-env

# OR restart (brief downtime)
pm2 restart ecosystem.config.js --update-env
```

To target a specific app by name:
```bash
pm2 reload app1 --update-env
```

To switch to a named env block (e.g. `env_production`):
```bash
pm2 restart ecosystem.config.js --env production --update-env
```

> **Note:** After applying changes, run `pm2 save` to persist the new env state across reboots.

---

## Log Management

### View Logs
```bash
pm2 logs            # All logs
pm2 logs [id/name]  # Specific app logs
pm2 flush           # Clear all logs
```

### Log Rotation
To handle large execution logs, it's recommended to install `pm2-logrotate`:

```bash
pm2 install pm2-logrotate

# Configure rotation (optional)
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 30
```
