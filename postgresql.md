## Networking fundamentals (important)

Two files control network behavior:
- `postgresql.conf`: where PostgreSQL listens (`listen_addresses`)
- `pg_hba.conf`: who can authenticate from which IP/subnet

Example:
- `listen_addresses='*'` allows listening on all interfaces
- `pg_hba.conf` still decides which client IP ranges may connect

## Installation (Ubuntu/Debian)


## Section A - Windows (Laragon)

### A1) Set or change `postgres` password

Open Laragon Terminal:

```bash
psql -U postgres
```
or
```bash
sudo -u postgres psql
```
For Mac
```bash
psql postgres
```

Then in psql:

```sql
ALTER USER postgres WITH PASSWORD '123456';
\q
```

Or in mac
Create postgresql user
```sql
CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD '123456';
```

### A2) Configure PostgreSQL to listen on LAN

Typical Laragon path:

```text
C:\laragon\data\postgresql
```

Edit `postgresql.conf`:

```ini
listen_addresses = '*'
```

Edit `pg_hba.conf` and add one rule at the bottom (example):

```text
host    all    all    192.168.1.0/24    scram-sha-256
```
## CIDR cheat sheet (`pg_hba.conf`)

| CIDR | Meaning | Typical use |
|---|---|---|
| `192.168.1.0/24` | only `192.168.1.x` | recommended in homes/small offices |
| `192.168.0.0/16` | any `192.168.x.x` | broader private LAN access |
| `10.0.0.0/8` | any `10.x.x.x` | enterprise/private networks |
| `0.0.0.0/0` | any IPv4 address | avoid unless absolutely necessary |

Use the narrowest subnet possible.

---

### A3) Open Windows Firewall (port `5432`)

PowerShell (Run as Administrator):

```powershell
New-NetFirewallRule -DisplayName "PostgreSQL (Laragon)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5432
```

Optional hardening (restrict source subnet):

```powershell
Set-NetFirewallRule -DisplayName "PostgreSQL (Laragon)" -RemoteAddress 192.168.1.0/24
```

### A4) Restart and verify

Restart from Laragon UI (Stop -> Start All), then verify:

```powershell
netstat -ano | findstr :5432
```

Find local IP:

```bash
ipconfig
```

Remote test from another machine:

```bash
psql -h your_windows_ip -p 5432 -U postgres -d postgres
```

---

## Section B - Linux (Ubuntu/Debian)

### B1) Install PostgreSQL

```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

Check status:

```bash
sudo systemctl status postgresql --no-pager
psql --version
```

## Setup and Configuration

### 1) Set or change `postgres` password

```bash
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'your_new_secure_password';"
```

### 2) Locate active config files

```bash
sudo -u postgres psql -t -P format=unaligned -c "SHOW config_file;"
sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file;"
```

### 3) Configure network access

Edit `postgresql.conf` (use the path found in step 2):

```bash
sudo nano $(sudo -u postgres psql -t -P format=unaligned -c "SHOW config_file;")
```

Set `listen_addresses` to allow external connections:

```ini
listen_addresses = '*'
```

Edit `pg_hba.conf` (use the path found in step 2):

```bash
sudo nano $(sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file;")
```

And append at the bottom:

```text
# Allow specific subnet (recommended)
host    all    all    192.168.1.0/24    scram-sha-256

# OR Allow from anywhere (all IPs)
host    all    all    0.0.0.0/0         scram-sha-256
```

### CIDR cheat sheet (`pg_hba.conf`)

| CIDR | Meaning | Typical use |
|---|---|---|
| `192.168.1.0/24` | only `192.168.1.x` | recommended in homes/small offices |
| `192.168.0.0/16` | any `192.168.x.x` | broader private LAN access |
| `10.0.0.0/8` | any `10.x.x.x` | enterprise/private networks |
| `0.0.0.0/0` | any IPv4 address | avoid unless absolutely necessary |

Restart:

```bash
sudo systemctl restart postgresql
```

### 4) Open Linux firewall

If UFW is enabled:

```bash
# Allow from a specific subnet (recommended)
sudo ufw allow from 192.168.1.0/24 to any port 5432 proto tcp

# OR Allow from anywhere (all IPs)
sudo ufw allow 5432/tcp

sudo ufw status verbose
```

If firewalld is enabled:

```bash
# Allow from a specific subnet (recommended)
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port protocol="tcp" port="5432" accept'

# OR Allow from anywhere (all IPs)
sudo firewall-cmd --permanent --add-port=5432/tcp

sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

### 5) Verify listener and remote access

```bash
sudo ss -tulpen | grep 5432
```

Remote test:

```bash
psql -h your_linux_ip -p 5432 -U postgres -d postgres
```

## Memory Configuration

PostgreSQL's default memory settings are often too conservative for modern servers (designed to run on older systems with very little RAM). To optimize performance, you should adjust these settings in `postgresql.conf` based on your server's available RAM.
## Section C - macOS (Homebrew)

### C1) Install PostgreSQL

Using [Homebrew](https://brew.sh/):

```bash
brew update
brew install postgresql
```

Start the service so it runs in the background and restarts at login:

```bash
brew services start postgresql
```

Check status:

```bash
brew services info postgresql
psql --version
```

### C2) Connect and set password

Homebrew installs PostgreSQL and automatically creates a superuser with your macOS username, rather than a `postgres` user by default. The default database is `postgres`.

Log in:

```bash
psql postgres
```

(Optional) Create a `postgres` user for consistency with other systems:

```sql
CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD '123456';
\q
```

Or just change your current macOS user's database password:

```sql
ALTER USER CURRENT_USER WITH PASSWORD 'your_new_secure_password';
\q
```

### C3) Locate active config files

```bash
psql postgres -t -P format=unaligned -c "SHOW config_file;"
psql postgres -t -P format=unaligned -c "SHOW hba_file;"
```
*(Typical locations: `/usr/local/var/postgres/` on Intel Macs, `/opt/homebrew/var/postgres/` on Apple Silicon)*

### C4) Configure network access

Edit `postgresql.conf` (using the path found above):

```ini
listen_addresses = '*'
```

Edit `pg_hba.conf` (append at bottom):

```text
host    all    all    192.168.1.0/24    scram-sha-256
```

Restart to apply changes:

```bash
brew services restart postgresql
```

### C5) Open macOS Firewall

If the built-in macOS Application Firewall is enabled:
1. Open **System Settings** > **Network** > **Firewall** (or **System Preferences** > **Security & Privacy** > **Firewall** on older versions).
2. Click **Options...** or **Firewall Options...**
3. Click the **+** button, press `Cmd + Shift + G`, and enter the path to the `postgres` executable (e.g., `/opt/homebrew/opt/postgresql/bin/postgres` or `/usr/local/opt/postgresql/bin/postgres`).
4. Set it to **Allow incoming connections**.
5. Click **OK**.

### C6) Verify listener and remote access

Check if it's listening on port 5432:

```bash
lsof -i :5432
```

Find local IP:

```bash
ipconfig getifaddr en0
```

Remote test from another machine on the LAN:

```bash
psql -h your_mac_ip -p 5432 -U postgres -d postgres
```

---

## Client connection settings

Edit `postgresql.conf`:
```bash
sudo nano $(sudo -u postgres psql -t -P format=unaligned -c "SHOW config_file;")
```

Key memory parameters to tune:

- **`shared_buffers`**: The amount of memory PostgreSQL uses for shared memory buffers (caching data).
  - *Default*: Usually 128MB.
  - *Recommendation*: Set to 25% of your total system RAM (e.g., `4GB` for a 16GB server).

- **`work_mem`**: The memory used for internal sort operations and hash tables before writing to temporary disk files.
  - *Default*: Usually 4MB.
  - *Recommendation*: Calculate carefully, as this is allocated *per connection* or *per sort operation*. For a server with 16GB RAM and 100 max connections, setting it to `16MB` or `32MB` is a good starting point.

- **`maintenance_work_mem`**: Memory used for maintenance operations like `VACUUM`, `CREATE INDEX`, and `ALTER TABLE`.
  - *Default*: Usually 64MB.
  - *Recommendation*: Set to 5% - 10% of total RAM, or higher (e.g., `1GB` or `2GB`), to speed up maintenance tasks.

- **`effective_cache_size`**: An estimate of how much memory is available for disk caching by the operating system and within the database itself. This helps the query planner decide whether to use indexes.
  - *Default*: Usually 4GB.
  - *Recommendation*: Set to 50% - 75% of your total system RAM.

> [!TIP]
> For an automated memory tuning calculation tailored to your specific hardware, consider using a tool like [PGTune](https://pgtune.leopard.in.ua/).

There are two different ways to set these memory parameters depending on whether you want to change them temporarily for a single task, or permanently for the whole server.

Here are the commands you need for both approaches:

### 1. The Temporary Method (Per Session)

This is the safest and most common way to change **`work_mem`** and **`maintenance_work_mem`**. It only affects your current database connection and reverts back to the default when you disconnect.

You can run these standard SQL commands directly in your query tool or application code before executing a heavy query:

```sql
-- Change it for the entire current session
SET work_mem = '256MB';

-- Change it only for the current transaction block
BEGIN;
SET LOCAL work_mem = '512MB';
SELECT * FROM huge_table ORDER BY date;
COMMIT; -- Reverts back to normal here

-- Reset back to the global default manually
RESET work_mem;
```

*Note: You **cannot** set `shared_buffers` this way, as it must be allocated at startup.*

### 2. The Permanent Method (Global)

To change the default values for the entire server permanently, you can use the `ALTER SYSTEM` command. This writes the changes to a file called `postgresql.auto.conf`, overriding your main configuration file.

Run these SQL commands as a superuser (like `postgres`):

```sql
-- Set global limits for dynamic memory
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET maintenance_work_mem = '1GB';

-- Set global limit for shared buffers
ALTER SYSTEM SET shared_buffers = '4GB';
```

### 3. Applying the Permanent Changes

Crucially, `ALTER SYSTEM` does not apply the changes instantly. You must tell PostgreSQL to load the new settings, and this behaves differently depending on the parameter:

**For `work_mem` and `maintenance_work_mem`:**
These can be applied without stopping the database. You just need to reload the configuration by running this SQL command:

```sql
SELECT pg_reload_conf();
```

**For `shared_buffers`:**
Because this memory must be claimed from the operating system all at once, **you must restart the PostgreSQL service entirely**. A simple reload will not work.

You will need to run a restart command from your server's terminal (not in SQL), which usually looks like this on Linux:

```bash
sudo systemctl restart postgresql
```

### 4. Monitoring Active Memory Usage

To effectively monitor active memory usage in PostgreSQL, you need to look at both real-time query execution and the internal memory contexts of the background processes.

Here are the most effective built-in tools and queries to monitor exactly how memory is being consumed.

#### Check Memory Used by Your Current Session

If you are running PostgreSQL 14 or newer, you can query a system view that exposes the exact memory allocation of your current database connection.

Run this to see the total RAM currently being consumed by your active session:

```sql
SELECT 
    pg_size_pretty(sum(used_bytes)) AS "Total Memory Used",
    pg_size_pretty(sum(total_bytes)) AS "Total Memory Allocated"
FROM pg_backend_memory_contexts;
```

If you want to see exactly which internal operations (like sorting or hashing) are eating that memory, you can list the top consumers:

```sql
SELECT name, type, pg_size_pretty(used_bytes) AS used
FROM pg_backend_memory_contexts
ORDER BY used_bytes DESC
LIMIT 10;
```

#### Inspect Memory of Other Active Connections

Because of security and architectural reasons, you cannot directly run a `SELECT` query to see the live memory contexts of *other* users' connections. However, you can command PostgreSQL to dump the memory usage of a specific active process ID (PID) directly into the server logs.

First, find the PID of the active query you want to inspect using `pg_stat_activity`:

```sql
SELECT pid, query, state, now() - query_start AS duration 
FROM pg_stat_activity 
WHERE state = 'active' AND pid <> pg_backend_pid();
```

Once you have the PID (for example, `12345`), execute this diagnostic function:

```sql
SELECT pg_log_backend_memory_contexts(12345);
```

This returns `true`, and you can then check your PostgreSQL server logs (e.g., in `/var/log/postgresql/`) to see a detailed breakdown of exactly how much memory that specific query is holding.

#### Check if Queries are Exceeding `work_mem`

One of the most critical aspects of memory monitoring is knowing if your `work_mem` is set too low. When a query exceeds its `work_mem` limit, it spills over and writes temporary files to the disk.

You can monitor this by checking `pg_stat_database`:

```sql
SELECT 
    datname AS database_name, 
    temp_files AS total_temp_files, 
    pg_size_pretty(temp_bytes) AS total_temp_bytes_written
FROM pg_stat_database
WHERE temp_files > 0;
```

*Note: This is a cumulative counter. If `temp_files` and `temp_bytes` are growing rapidly, it means active queries are heavily reliant on the disk for sorting/hashing because they do not have enough `work_mem`.*

#### Analyze Memory for a Specific Query

If you have a specific query that you suspect is a memory hog, you can prefix it with `EXPLAIN (ANALYZE, BUFFERS)` to see exactly how it utilizes the `shared_buffers` cache and dynamic memory.

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM huge_table ORDER BY created_at;
```

In the execution plan output, look for lines mentioning **Sort Method** or **Hash**. It will explicitly state whether it performed the operation in memory (e.g., `Sort Method: quicksort  Memory: 25kB`) or if it had to spill to disk (e.g., `Sort Method: external merge  Disk: 45000kB`).

## Helpful operational commands

### Service and health

```bash
sudo systemctl status postgresql --no-pager
sudo -u postgres psql -c "SELECT now(), version();"
```

### Roles and databases

```bash
sudo -u postgres psql -c "\du"
sudo -u postgres psql -c "\l"
```

### Create app role and database (recommended pattern)

```bash
sudo -u postgres psql -c "CREATE USER app_user WITH PASSWORD 'strong_password_here';"
sudo -u postgres psql -c "CREATE DATABASE app_db OWNER app_user;"
```

### Backup and restore

Backup one DB:

```bash
pg_dump -h 127.0.0.1 -U postgres -F c -d app_db -f app_db_$(date +%F).dump
```

Restore:

```bash
pg_restore -h 127.0.0.1 -U postgres -d app_db --clean --if-exists app_db_2026-05-06.dump
```

### Copy / Duplicate a database

Method 1: Using `TEMPLATE` (fastest, requires no active connections to source DB). Run inside `psql`:

```sql
CREATE DATABASE new_db WITH TEMPLATE original_db;
```

Method 2: Using `pg_dump` and piping to `psql` (useful for copying between different servers, or if source DB is active):

```bash
pg_dump -h source_host -U postgres -C original_db | psql -h target_host -U postgres -d postgres
```

### Inspect active connections

```sql
SELECT usename, datname, client_addr, state
FROM pg_stat_activity
ORDER BY backend_start DESC;
```

## Common errors and fixes

- `no pg_hba.conf entry for host ...`
  - Client IP not covered by CIDR in `pg_hba.conf`
  - PostgreSQL not restarted after changes
- `password authentication failed for user ...`
  - Wrong password or auth method mismatch in `pg_hba.conf`
- `connection refused`
  - PostgreSQL service down or `listen_addresses` still localhost-only
- `operation timed out` or `no route to host`
  - OS firewall blocking `5432`

## Security baseline (recommended)

- Do not use `0.0.0.0/0` unless required
- Use app-specific DB users, not `postgres`
- Keep CIDR as narrow as possible (`/24` preferred)
- Prefer TLS when traffic leaves trusted LAN

## Fast checklist

1. Set password for `postgres`
2. Set `listen_addresses='*'`
3. Add subnet rule in `pg_hba.conf`
4. Open firewall `5432` for trusted subnet only
5. Tune Memory (`shared_buffers`, `work_mem`)
6. Restart PostgreSQL
7. Test with `psql` from another machine

## Uninstalling PostgreSQL (Linux)

> [!WARNING]
> These steps will remove packages and may delete database files. Back up any data you need before proceeding.

### Stop PostgreSQL service

```bash
sudo systemctl stop postgresql
sudo systemctl disable postgresql
```

### Debian / Ubuntu (APT)

Remove packages and purge configuration files:
```bash
sudo apt purge -y 'postgresql*'
sudo apt autoremove -y
```

Remove data files (irreversible):
```bash
sudo rm -rf /var/lib/postgresql /etc/postgresql /var/log/postgresql /var/run/postgresql
sudo deluser --remove-home postgres || sudo userdel -r postgres || true
```

### RHEL / CentOS / Fedora (DNF/YUM)

```bash
sudo systemctl stop postgresql
sudo dnf remove -y postgresql-server postgresql-contrib || sudo yum remove -y postgresql-server postgresql-contrib
sudo rm -rf /var/lib/pgsql /var/lib/pgsql/data /var/log/postgresql
sudo userdel -r postgres || true
```

### Arch Linux (pacman)

```bash
sudo systemctl stop postgresql
sudo pacman -Rns --noconfirm postgresql
sudo rm -rf /var/lib/postgres /var/log/postgres
sudo userdel -r postgres || true
```

### macOS (Homebrew)

```bash
brew services stop postgresql
brew uninstall postgresql
```

- Remove data files (irreversible):

```bash
rm -rf /usr/local/var/postgres   # Intel Mac
rm -rf /opt/homebrew/var/postgres # Apple Silicon Mac
```

### Source-based / Custom installs

- If PostgreSQL was compiled from source or installed in a custom prefix, remove the installation directory and data dir manually. Check `which postgres` and `pg_config --bindir`.

### Docker / Container installs

- Remove containers and images:

```bash
docker rm -f <container_name_or_id>
docker rmi <image_name_or_id>
```

- Remove volume if used:

```bash
docker volume rm <volume_name>
```

### Clean up apt sources and keys (if you added PostgreSQL repo)

```bash
# Remove external APT source list (example)
sudo rm -f /etc/apt/sources.list.d/pgdg.list
sudo apt-key del <KEYID> || true
sudo apt update
```

### Verify removal

```bash
which psql || echo "psql not found"
sudo ss -tulpen | grep 5432 || echo "no listener on 5432"
```

### Notes

- `purge` or `--purge` removes packaged config files; it may not remove database data.
- Always back up `/var/lib/postgresql` (or your data directory) before deleting.
- Removing the `postgres` system user may affect other services if they rely on it.

