# Redis — Setup, Testing, and Usage on Linux

## Overview
Redis is an in-memory data structure store used as a database, cache, and message broker.

## Installation / Setup (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install redis-server
```
- Linux (apt / yum):
  - Ubuntu/Debian: `sudo apt update && sudo apt install redis-server`
  - CentOS/RHEL: use EPEL or build from source.
- Docker (recommended for quick testing):
  - `docker run --name redis -p 6379:6379 -d redis:latest`
- macOS:
  - Install Redis via Homebrew: `brew install redis`
- Windows: Use WSL or the official Microsoft port alternatives; Docker is recommended on Windows.

After install, start the server:

- **Linux (systemd):**
  ```bash
  sudo systemctl enable --now redis-server
  ```

- **macOS (Homebrew):**
  To start Redis as a background service:
  ```bash
  brew services start redis
  ```
  *(Alternatively, to run it in the foreground: `redis-server`)*


### Enable Auto-start on Ubuntu
To ensure Redis starts automatically when the server reboots:

```bash
sudo systemctl enable redis-server
sudo systemctl start redis-server
sudo systemctl status redis-server # Verify it is running
```

## Basic Configuration

The main configuration file is typically located at `/etc/redis/redis.conf`.

Important settings:
- `bind 127.0.0.1` — restrict network access (default).
- `protected-mode yes` — keep for safety.
- `requirepass <password>` — set a password for production.
- Persistence: `save` (RDB) and `appendonly yes` (AOF).
- `maxmemory` and `maxmemory-policy` — control eviction.

After making changes, restart the service:
```bash
sudo systemctl restart redis-server
```

## Testing & Verification (Local)

- Connect with CLI: `redis-cli`
- Ping test: `redis-cli ping` → `PONG`
- Basic set/get:
  - `redis-cli set mykey "hello"`
  - `redis-cli get mykey` → `"hello"`

## Remote Access and Security

By default, Redis refuses external connections (protected-mode). To allow remote access, it is strongly recommended to set a password rather than disabling protected mode.

### 1. Set a Password
1. Edit `/etc/redis/redis.conf`.
2. Find the `# requirepass` line, uncomment it, and set a strong password:
   ```text
   requirepass YourStrongPasswordHere
   ```

### 2. Configure Bind Address
1. In the same config file, find `bind 127.0.0.1`.
2. Change it to listen on the server's LAN IP or all interfaces:
   ```text
   bind 0.0.0.0
   ```
   *(Note: Binding to `0.0.0.0` is risky without a firewall.)*

### 3. Restart Redis
```bash
sudo systemctl restart redis-server
```

### 4. Configure Firewall (UFW)
Open port 6379 only for trusted IP addresses:
```bash
sudo ufw allow from <TRUSTED_CLIENT_IP> to any port 6379 proto tcp
```

> [!CAUTION]
> Never expose Redis to the public internet (bind 0.0.0.0) without setting a strong password and configuring firewall rules. Hackers frequently target open Redis instances.

## Testing Remote Connection

To verify if Redis is accessible from another computer, run the following command from the client machine:

```bash
redis-cli -h <192.168.0.165> -p 6379 -a YourStrongPasswordHere ping
```
If the connection is successful, it will return `PONG`.

Alternatively, use `nc` or `telnet` to check if the port is open and accessible from the client:
```bash
nc -vz <SERVER_IP_ADDRESS> 6379
# or
telnet <SERVER_IP_ADDRESS> 6379
```

## Usage Patterns

- **Caching:** store computed values to reduce DB load (use TTLs).
- **Session storage:** fast read/write for user sessions.
- **Rate limiting:** use INCR and EXPIRE to implement per-user rate limits.

## Troubleshooting

- **High memory usage:** check large keys with `redis-cli --bigkeys`.
- **Connection refused:** ensure Redis is running, check `bind` in `redis.conf`, and verify firewall settings.
- **Slow commands:** run `SLOWLOG GET` to identify slow operations.
