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

### Memory Configuration
To configure Redis memory limits, edit `/etc/redis/redis.conf` and set `maxmemory` and `maxmemory-policy`:

```text
# Set maximum memory limit (e.g., 256mb, 1gb)
maxmemory 256mb

# Set the eviction policy when maxmemory is reached
# common policies: 
# volatile-lru (evict keys with an expire set using LRU)
# allkeys-lru (evict any key using LRU)
# noeviction (return errors when memory limit was reached)
maxmemory-policy allkeys-lru
```

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

## Data Types and Commands

Redis supports various data structures. Here is how you can interact with different formats using `redis-cli`:

### Strings
Strings are the most basic type in Redis. You can also use them for numbers.
```bash
# Set a string
set my_key "Hello World"
# Get a string
get my_key

# Set with expiration (in seconds)
setex temp_key 60 "I will expire in a minute"
```

### Numbers
Numbers are stored as strings but can be manipulated as integers or floats.
```bash
# Set a number
set counter 100
# Increment by 1
incr counter
# Increment by specific amount
incrby counter 50
# Decrement
decr counter
```

### Lists
Lists are collections of string elements sorted according to the order of insertion.
```bash
# Add elements to the left (head) of the list
lpush my_list "apple"
lpush my_list "banana"

# Add elements to the right (tail) of the list
rpush my_list "cherry"

# Get all elements from the list (0 to -1 means all)
lrange my_list 0 -1

# Get a specific element by index (e.g., index 1)
lindex my_list 1

# Remove a specific item by value (e.g., remove 1 occurrence of "apple")
lrem my_list 1 "apple"

# Pop an element from the left (removes and returns it)
lpop my_list

# Pop an element from the right (removes and returns it)
rpop my_list
```

### JSON
To use JSON in Redis, you typically need the RedisJSON module installed (often available in Redis Stack).
```bash
# Set a JSON object
json.set user:1 $ '{"name": "Alice", "age": 30, "active": true}'

# Get the entire JSON object
json.get user:1

# Get a specific field
json.get user:1 $.name

# Update a specific field
json.set user:1 $.age 31
```

## Using Redis with Node.js

To interact with Redis in Node.js, the most popular client is `redis` (node-redis).

### 1. Installation
```bash
npm install redis
```

### 2. Basic Example
Here is an example demonstrating connection, strings, and lists.
```javascript
const { createClient } = require('redis');

async function runRedisExample() {
  // 1. Create and connect the client
  const client = createClient({
    // url: 'redis://alice:foobared@awesome.redis.server:6380' // For remote with password
  });

  client.on('error', err => console.error('Redis Client Error', err));

  await client.connect();
  console.log('Connected to Redis!');

  // 2. Working with Strings
  await client.set('my_key', 'Hello Node.js');
  const value = await client.get('my_key');
  console.log('my_key:', value); // Hello Node.js

  // 3. Working with Lists
  const listKey = 'my_node_list';
  
  // Add items
  await client.lPush(listKey, ['apple', 'banana']);
  await client.rPush(listKey, 'cherry');

  // Get the whole list
  const fullList = await client.lRange(listKey, 0, -1);
  console.log('Full List:', fullList); // ['banana', 'apple', 'cherry']

  // Get a specific item by index (e.g., index 1)
  const itemAtIndex1 = await client.lIndex(listKey, 1);
  console.log('Item at index 1:', itemAtIndex1); // 'apple'

  // Remove a specific item by value (remove 1 occurrence of 'apple')
  await client.lRem(listKey, 1, 'apple');

  // Pop an item from the left (removes and returns it)
  const poppedItem = await client.lPop(listKey);
  console.log('Popped from left:', poppedItem); // 'banana'

  // 4. Disconnect when done
  await client.disconnect();
}

runRedisExample();
```

## Usage Patterns

- **Caching:** store computed values to reduce DB load (use TTLs).
- **Session storage:** fast read/write for user sessions.
- **Rate limiting:** use INCR and EXPIRE to implement per-user rate limits.

## Troubleshooting

- **High memory usage:** check large keys with `redis-cli --bigkeys`.
- **Connection refused:** ensure Redis is running, check `bind` in `redis.conf`, and verify firewall settings.
- **Slow commands:** run `SLOWLOG GET` to identify slow operations.
