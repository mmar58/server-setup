# Redis — Setup, Testing, Benefits, and Usage

## Overview
Redis is an in-memory data structure store used as a database, cache, and message broker. It supports strings, hashes, lists, sets, sorted sets, bitmaps, hyperloglogs, and streams.

## Installation / Setup

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


Or with Docker the container starts automatically.

## Basic Configuration

- Config file: typically `/etc/redis/redis.conf`.
- Important settings:
  - `bind 127.0.0.1` — restrict network access.
  - `protected-mode yes` — keep for safety.
  - `requirepass <password>` — set a password for production.
  - Persistence: `save` (RDB) and `appendonly yes` (AOF).
  - `maxmemory` and `maxmemory-policy` — control eviction.

After changes, restart the server: `sudo systemctl restart redis`.

## Testing & Verification

- Connect with CLI: `redis-cli`
- Ping test: `redis-cli ping` → `PONG`
- Basic set/get:
  - `redis-cli set mykey "hello"`
  - `redis-cli get mykey` → `"hello"`
- Persistence check:
  - Create a key, restart Redis, verify key remains (if persistence enabled).
- Pub/Sub test:
  - Terminal 1: `redis-cli subscribe mychannel`
  - Terminal 2: `redis-cli publish mychannel "hi"`
- Benchmarking: use `redis-benchmark` for simple throughput tests, e.g.:

```
redis-benchmark -h 127.0.0.1 -p 6379 -c 50 -n 10000
```

## Usage Patterns

- Caching: store computed values to reduce DB load (use TTLs and suitable eviction policies).
- Session storage: fast read/write for user sessions.
- Message broker: Pub/Sub for simple messaging; Streams for more robust messaging workflows.
- Rate limiting: use INCR and EXPIRE to implement per-user rate limits.
- Leaderboards: use sorted sets (`ZADD`, `ZRANGE`) for scoring systems.

## Benefits

- Extremely low latency and high throughput — suitable for real-time applications.
- Rich data structures simplify implementations (counters, queues, sets, sorted structures).
- Flexible persistence options (RDB snapshots, AOF logs).
- Simple operational model and strong ecosystem (clients, monitoring, exporters).

## Best Practices

- Use authentication (`requirepass`) and firewall rules; bind to localhost if possible.
- Run Redis on dedicated instances for production workloads.
- Set `maxmemory` and choose an eviction policy appropriate to your use-case (e.g., `allkeys-lru` for general caching).
- Enable AOF if you need durable write persistence; tune `appendfsync` per durability/performance needs.
- Use monitoring (Redis `INFO`, `SLOWLOG`, exporters for Prometheus) to track memory, hits/misses, CPU.
- Backup strategy: snapshotting and AOF backups; test restores regularly.

## Troubleshooting

- High memory usage: check large keys with `MEMORY USAGE <key>` and `redis-cli --bigkeys`.
- Evictions: monitor `evicted_keys` and adjust `maxmemory` or change eviction policy.
- Connection refused: ensure Redis is running, check `bind` and firewall settings.
- Slow commands: run `SLOWLOG GET` to identify slow operations.

## Remote access and the "protected-mode" error

This error is a security feature built into Redis. By default, it refuses to talk to external machines unless you have explicitly secured it or told it to be "open."

To fix this, you need to modify the settings on the device where Redis is actually running (the target/server machine), not on your Windows client.

---

### Solution 1: Disable Protected Mode (Fastest for Testing)

If you are on a private, trusted network and just want it to work immediately, you can turn off this restriction.

**Option A: Using `redis-cli` on the Server**
If you have access to the terminal of the machine running Redis, run:

1. `redis-cli`
2. `CONFIG SET protected-mode no`
3. (Optional) `CONFIG REWRITE`  # saves the change to the config file if possible

Notes:
- `CONFIG SET` changes take effect immediately but may not survive a restart unless you run `CONFIG REWRITE` (and Redis can write the config file) or edit the file directly.
- To check current values from the server run:

```
redis-cli CONFIG GET protected-mode
redis-cli CONFIG GET bind
redis-cli CONFIG GET requirepass
```

**Option B: Edit the Configuration File**

1. Open your `redis.conf` file (usually in `/etc/redis/` on Linux).
2. Find the line: `protected-mode yes` and change it to: `protected-mode no`
3. Find the line `bind 127.0.0.1` and change it to `bind 0.0.0.0` or your server's specific LAN IP so it listens to external requests.
4. Restart the Redis service:

```
sudo systemctl restart redis
# or on some distros:
sudo systemctl restart redis-server
```

---

### Solution 2: Set a Password (Recommended for Security)

Setting a password satisfies Redis' security requirements while allowing external connections.

1. Open your `redis.conf` file.
2. Find the `# requirepass` line, uncomment it and set a strong password:

```
requirepass YourStrongPasswordHere
```

3. Make sure `bind` is set appropriately (see above).
4. Restart Redis.

How to connect after setting a password (from Windows CMD or any client):

```
redis-cli -h <IP_ADDRESS> -a YourStrongPasswordHere ping
```

For Redis 6+ consider using ACLs instead of a single global password. Example (run on server):

```
ACL SETUSER default on >YourStrongPassword ~* +@all
```

---

### Docker-specific notes

If Redis runs inside Docker, you must change settings inside the container (or mount a config file). Examples:

Run Redis quickly (not recommended for production without extra security):

```
docker run -d --name redis -p 6379:6379 redis:latest
```

Mount a custom config and run Redis with it:

```
docker run -d --name redis -v /path/to/redis.conf:/usr/local/etc/redis/redis.conf:ro \
  -p 6379:6379 redis:latest redis-server /usr/local/etc/redis/redis.conf
```

Exec into the container to run the same `redis-cli` commands:

```
docker exec -it redis redis-cli CONFIG SET protected-mode no
docker exec -it redis redis-cli CONFIG REWRITE
```

Be careful: when you publish `6379` via `-p` you expose it to the host network. Use firewall rules or avoid publishing the port publicly.

---

### Firewall & network rules (always restrict access)

Use host firewall rules to restrict which IPs can reach Redis. Examples:

UFW (Ubuntu):

```
sudo ufw allow from <TRUSTED_IP> to any port 6379 proto tcp
# or restrict to a subnet:
sudo ufw allow from 192.168.1.0/24 to any port 6379 proto tcp
```

iptables (example):

```
sudo iptables -A INPUT -p tcp -s <TRUSTED_IP_OR_SUBNET> --dport 6379 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 6379 -j DROP
```

Make rules persistent (e.g., `iptables-persistent` or `nftables` depending on your distro).

---

### Encrypted connections (TLS) & tunnels

Redis 6+ supports TLS natively; enabling it requires configuring `tls-port`, certificates, and disabling non-TLS `port` if desired. For many deployments a simpler approach is to:

- Use an SSH tunnel for admin tasks:

```
ssh -L 6379:127.0.0.1:6379 user@redis-server
# Then locally: redis-cli -p 6379 ping
```

- Or terminate TLS with a proxy (stunnel, HAProxy, or a sidecar) in front of Redis.

To test a TLS-enabled Redis with `redis-cli`:

```
redis-cli --tls -h <HOST> -p <TLS_PORT> --cacert ca.pem -a YourStrongPasswordHere ping
```

---

### Quick checklist

| Step | Action | Why? |
| --- | --- | --- |
| **1. Bind Address** | Change `bind 127.0.0.1` to `bind 0.0.0.0` | Allows Redis to "listen" to network cards other than the local one. |
| **2. Security** | Either `protected-mode no` **OR** set `requirepass` (or ACLs) | Tells Redis you understand the risks of remote access. |
| **3. Firewall** | Open Port `6379` only for trusted IPs | Ensures the OS doesn't block the incoming request before it reaches Redis. |

> [!CAUTION]
> **Warning:** Never set `protected-mode no` or bind to `0.0.0.0` if your Redis server is directly exposed to the internet without a hardware firewall. Hackers frequently scan for open Redis ports to inject malware or steal data.

---

If you'd like, I can add exact distro-specific commands (UFW, nftables, or firewalld) or a Docker Compose example with a mounted secure `redis.conf`.


## Example snippets

- Simple caching with TTL:

```
SET user:12345:data "...json..." EX 3600

GET user:12345:data
```

- Rate limiter (pseudo):

```
INCR user:12345:reqs
EXPIRE user:12345:reqs 60
```

## Quick Commands Reference

- `redis-cli ping` — check server
- `redis-cli INFO` — server stats
- `redis-cli MONITOR` — live command stream (debug)
- `redis-cli --bigkeys` — find big keys
- `redis-benchmark` — performance tests

## References

- Official docs: https://redis.io/
- Redis CLI guide: https://redis.io/docs/manual/cli/

---
Created: concise Redis setup, testing, benefits, and usage guide.
