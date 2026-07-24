# MariaDB — Setup, Testing, and Usage on Linux

## Overview
MariaDB is a popular, open-source relational database fork of MySQL. It is highly compatible with MySQL and widely used as a drop-in replacement.

## Installation / Setup (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install mariadb-server
```

Enable auto-start on reboot:

```bash
sudo systemctl enable mariadb
sudo systemctl start mariadb
sudo systemctl status mariadb
```

### Initial Security Configuration (Important)
After installation, always run the secure installation script to set the root password and remove test databases:

```bash
sudo mysql_secure_installation
```

## Basic Configuration & Remote Access

The main configuration file is typically located at `/etc/mysql/mariadb.conf.d/50-server.cnf` (on Ubuntu/Debian) or `/etc/my.cnf` (on CentOS/RHEL).

To allow remote connections, edit the configuration file:

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Find the `bind-address` line. By default, it restricts access to localhost. Change it to allow connections from anywhere (or a specific IP):

```ini
# Change from 127.0.0.1
bind-address = 0.0.0.0
```

Restart MariaDB to apply changes:
```bash
sudo systemctl restart mariadb
```

### Allow Remote Access via Firewall (UFW)
Open port `3306` (default MariaDB port) for trusted IP addresses:

```bash
sudo ufw allow from <TRUSTED_CLIENT_IP> to any port 3306 proto tcp
```

### Create a Database and Remote User
Connect to MariaDB:
```bash
sudo mysql -u root -p
```

Run these SQL commands:
```sql
CREATE DATABASE my_app;
-- Create user allowed to connect from any IP ('%') or a specific IP
CREATE USER 'app_user'@'%' IDENTIFIED BY 'StrongPassword123';
GRANT ALL PRIVILEGES ON my_app.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
EXIT;
```

## Memory Configuration & Optimization

### How Memory Works in MariaDB

MariaDB allocates memory in two main ways:
1. **Global Buffers**: Allocated once when the server starts and shared among all connections. The largest and most important is the `innodb_buffer_pool_size`.
2. **Per-Thread (Per-Connection) Buffers**: Allocated dynamically for each active connection when needed (e.g., for sorting or joining tables). 

**Total Memory Usage Calculation:**
To prevent the OS from killing MariaDB (OOM killer), ensure this formula stays below your total system RAM:
`Global Buffers + (Max Connections × Per-Thread Memory) < Total System RAM`

---

### Setting Memory Parameters

There are three ways to adjust memory parameters: via the configuration file (permanent), dynamically across the server (global), or per-session (temporary).

#### 1. The Permanent Method (Config File)

The most robust way to configure MariaDB is by editing the configuration file (`/etc/mysql/mariadb.conf.d/50-server.cnf` on Ubuntu/Debian). Changes here survive a server reboot.

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Key memory parameters to tune inside the `[mysqld]` section:

- **`innodb_buffer_pool_size`** (Global): Caches data and indexes in memory.
  - *Recommendation*: Set to 50% - 75% of total RAM on a dedicated DB server.
- **`max_connections`**: Maximum concurrent clients. Keep this reasonable (e.g. `100` or `200`) to avoid per-thread memory exhaustion.
- **`sort_buffer_size`** (Per-Thread): Used for sorting. Keep it low (e.g. `2M` or `4M`) globally.
- **`join_buffer_size`** (Per-Thread): Used for joins without indexes. Keep it low globally (e.g. `2M`).

Example `[mysqld]` section:
```ini
[mysqld]
innodb_buffer_pool_size = 4G
max_connections = 150
sort_buffer_size = 2M
join_buffer_size = 2M
```

*Always restart MariaDB after changing the configuration file:*
```bash
sudo systemctl restart mariadb
```

#### 2. The Dynamic Global Method (No Restart)

Modern versions of MariaDB allow you to change many global variables—including the `innodb_buffer_pool_size`—instantly using SQL without restarting the server. 

> [!WARNING]
> Dynamic `SET GLOBAL` changes are lost when the server reboots! You must also add them to your `.cnf` file if you want them to be permanent.

Run these SQL commands as a highly privileged user inside the MariaDB prompt:

```sql
-- Change max_connections instantly
SET GLOBAL max_connections = 250;

-- Change the InnoDB buffer pool instantly (MariaDB 10.2.2+)
SET GLOBAL innodb_buffer_pool_size = 4294967296; -- 4GB in bytes

-- Verify the new buffer pool size
SHOW GLOBAL VARIABLES LIKE 'innodb_buffer_pool_size';
```

#### 3. The Temporary Method (Per Session)

If you have a single heavy query (like a massive report), you shouldn't increase the global per-thread buffers because it wastes memory for all other connections. Instead, change it temporarily for just that session.

Run this in your SQL client before your heavy query:

```sql
-- Increase sort and join buffers just for this session (32MB)
SET SESSION sort_buffer_size = 33554432;
SET SESSION join_buffer_size = 33554432;

-- Run your heavy query
SELECT * FROM huge_table t1 JOIN massive_table t2 ON t1.id = t2.id ORDER BY t1.date;

-- Memory goes back to default automatically when you disconnect.
```

### 4. Monitoring Active Memory Usage

Unlike PostgreSQL, MariaDB relies more heavily on its internal storage engine (InnoDB) to manage memory, but you can still effectively monitor active memory consumption using built-in commands and the `information_schema`.

#### Check InnoDB Buffer Pool Usage

The InnoDB buffer pool is usually the largest consumer of memory. You can check its current utilization to see if you need to increase it:

```sql
SHOW ENGINE INNODB STATUS\G
```
*(Look for the "BUFFER POOL AND MEMORY" section to see total memory allocated, free buffers, and database pages).*

For a quicker overview of buffer pool usage via variables:

```sql
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_pages_%';
```

#### Inspect Memory of Active Connections (Per-Thread)

If you suspect active queries are consuming too much per-thread memory (like `sort_buffer_size`), you can inspect the active process list:

```sql
SHOW FULL PROCESSLIST;
```
This shows you all running queries, their state (e.g., "Sorting result"), and how long they have been running.

To dig deeper into exactly how much memory MariaDB is allocating globally and per thread/connection, you can query the `information_schema`:

```sql
-- View memory allocated by various internal MariaDB events
SELECT event_name, current_alloc 
FROM information_schema.memory_summary_global_by_event_name 
ORDER BY current_alloc DESC 
LIMIT 10;
```

#### Analyze Memory for a Specific Query

If you want to know if a specific query is sorting in memory or spilling to disk (which indicates `sort_buffer_size` might be too small), you can use `ANALYZE` or `EXPLAIN`:

```sql
EXPLAIN FORMAT=JSON SELECT * FROM huge_table ORDER BY date_column;
```
Look for `"using_filesort": true` in the output. If it is filesorting a massive amount of data, it may be exceeding the sort buffer and writing temporary files to disk.

## Helpful Operational Commands

- **Backup a database:**
  ```bash
  mysqldump -u root -p my_app > my_app_backup_$(date +%F).sql
  ```

- **Restore a database:**
  ```bash
  mysql -u root -p my_app < my_app_backup_2026-05-06.sql
  ```

- **Inspect active processes/queries:**
  Inside the MySQL prompt:
  ```sql
  SHOW PROCESSLIST;
  -- or
  SHOW FULL PROCESSLIST;
  ```

- **Check MariaDB status and variables:**
  ```sql
  SHOW STATUS LIKE 'Threads_connected';
  SHOW VARIABLES LIKE 'innodb_buffer%';
  ```

## Troubleshooting

- **`Access denied for user`**: Check if the password is correct and if the user is allowed to connect from the specific host IP (`'user'@'host'`).
- **`Can't connect to MySQL server on 'ip'`**: Check if MariaDB is running, if `bind-address` is configured correctly, and if the OS firewall (UFW/iptables) allows port 3306.
- **High Memory Usage/OOM Kills**: Ensure `innodb_buffer_pool_size` + (`max_connections` * per-connection-buffers) does not exceed your system RAM.
