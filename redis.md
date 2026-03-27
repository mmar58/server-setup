# Redis — Setup, Testing, Benefits, and Usage

## Overview
Redis is an in-memory data structure store used as a database, cache, and message broker. It supports strings, hashes, lists, sets, sorted sets, bitmaps, hyperloglogs, and streams.

## Installation / Setup

- Linux (apt / yum):
  - Ubuntu/Debian: `sudo apt update && sudo apt install redis-server`
  - CentOS/RHEL: use EPEL or build from source.
- Docker (recommended for quick testing):
  - `docker run --name redis -p 6379:6379 -d redis:latest`
- macOS: `brew install redis`
- Windows: Use WSL or the official Microsoft port alternatives; Docker is recommended on Windows.

After install, start the server:

```
sudo systemctl enable --now redis
```

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
