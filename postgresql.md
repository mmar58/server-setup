# PostgreSQL setup for local network access (Laragon + Linux)

This guide is optimized for two common setups:
- Windows + Laragon
- Linux server (Ubuntu/Debian)

Goal:
- Run PostgreSQL locally
- Allow safe access from your local network
- Verify connectivity quickly
- Troubleshoot common issues

## Quick decision: which section should you follow?

- If PostgreSQL runs inside Laragon on Windows: use [Section A](#section-a--windows-laragon)
- If PostgreSQL runs on a Linux machine/VM: use [Section B](#section-b--linux-ubuntudebian)

## Networking fundamentals (important)

Two files control network behavior:
- `postgresql.conf`: where PostgreSQL listens (`listen_addresses`)
- `pg_hba.conf`: who can authenticate from which IP/subnet

Both must be correct.

Example:
- `listen_addresses='*'` allows listening on all interfaces
- `pg_hba.conf` still decides which client IP ranges may connect



## Section A - Windows (Laragon)

### A1) Set or change `postgres` password

Open Laragon Terminal:

```bash
psql -U postgres
```

Then in psql:

```sql
ALTER USER postgres WITH PASSWORD 'your_new_secure_password';
\q
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

### B2) Set or change `postgres` password

```bash
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'your_new_secure_password';"
```

### B3) Locate active config files

```bash
sudo -u postgres psql -t -P format=unaligned -c "SHOW config_file;"
sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file;"
```

### B4) Configure network access

In `postgresql.conf`:

```ini
listen_addresses = '*'
```

In `pg_hba.conf` (append at bottom):

```text
host    all    all    192.168.1.0/24    scram-sha-256
```

Restart:

```bash
sudo systemctl restart postgresql
```

### B5) Open Linux firewall

If UFW is enabled:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 5432 proto tcp
sudo ufw status verbose
```

If firewalld is enabled:

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port protocol="tcp" port="5432" accept'
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

### B6) Verify listener and remote access

```bash
sudo ss -tulpen | grep 5432
```

Remote test:

```bash
psql -h your_linux_ip -p 5432 -U postgres -d postgres
```

---

## Client connection settings

Use pgAdmin, DBeaver, HeidiSQL, TablePlus, or `psql`:

- Host: server LAN IP (`192.168.x.x` or `10.x.x.x`)
- Port: `5432`
- Username: `postgres` (or app-specific user)
- Password: configured password
- Database: `postgres` (or your app DB)
- SSL mode:
  - local LAN only: `disable` is common
  - untrusted networks: configure TLS and use `require`/`verify-full`

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

### Inspect active connections

```sql
SELECT usename, datname, client_addr, state
FROM pg_stat_activity
ORDER BY backend_start DESC;
```

## Common errors and fixes

`no pg_hba.conf entry for host ...`
- Client IP not covered by CIDR in `pg_hba.conf`
- Rule placed above/below conflicting rules
- PostgreSQL not restarted after changes

`password authentication failed for user ...`
- Wrong password
- Connecting to different server than expected
- Auth method mismatch in `pg_hba.conf`

`connection refused`
- PostgreSQL service down
- `listen_addresses` still localhost-only
- Wrong host/port

`operation timed out` or `no route to host`
- OS firewall blocking `5432`
- Different VLAN/subnet without route
- Cloud/network ACL or security group denies traffic

## Security baseline (recommended)

- Do not use `0.0.0.0/0` unless required
- Use app-specific DB users, not `postgres`
- Keep CIDR as narrow as possible (`/24` preferred)
- Rotate passwords periodically
- Keep PostgreSQL updated
- Prefer TLS when traffic leaves trusted LAN

## Fast checklist

1. Set password for `postgres`
2. Set `listen_addresses='*'`
3. Add subnet rule in `pg_hba.conf`
4. Open firewall `5432` for trusted subnet only
5. Restart PostgreSQL
6. Test with `psql` from another machine
