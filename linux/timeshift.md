# Timeshift Cheat Sheet & Server Backup Guide

Timeshift is a powerful open-source system snapshot and backup tool for Linux. It protects your system by taking incremental snapshots of the filesystem at regular intervals or on demand, which can be restored later to undo system-breaking changes.

> **Server Admin Note:**  
> Timeshift is designed to protect **system files, packages, and configurations** (`/`, `/etc`, `/usr`, etc.). It is **not** designed to back up user documents, website uploads, or active database directories (`/var/lib/mysql`, `/var/lib/redis`, `/home`). For server maintenance, use Timeshift to create safety checkpoints *before* system upgrades, kernel updates, or major configuration changes, while using dedicated backup tools (`mysqldump`, `pg_dump`, etc.) for databases.

---

## Snapshot Modes: RSYNC vs. BTRFS

| Mode | Description | Server Recommendation |
| :--- | :--- | :--- |
| **RSYNC** | Uses `rsync` and hard links. Works on any standard Linux filesystem (Ext4, XFS, etc.). First snapshot takes full disk size; subsequent snapshots only store changed files. | **Recommended** for most standard server setups using Ext4. |
| **BTRFS** | Uses built-in Btrfs filesystem capabilities to create instant, zero-overhead snapshots (`@` and `@home` subvolumes). | Use only if your server root partition is formatted as **Btrfs** with proper subvolumes. |

---

## Installation

### Ubuntu / Debian
```bash
sudo apt update
sudo apt install timeshift -y
```

### RHEL / CentOS / AlmaLinux / Rocky Linux
```bash
sudo dnf install epel-release -y
sudo dnf install timeshift -y
```

### Arch Linux
```bash
sudo pacman -S timeshift
```

---

## Basic Command-Line Usage

| Command | Description |
| :--- | :--- |
| `sudo timeshift --list` | List all stored snapshots and show backup device info |
| `sudo timeshift --create` | Create a new system snapshot immediately |
| `sudo timeshift --create --comments "message"` | Create a snapshot with a descriptive comment |
| `sudo timeshift --create --tags O` | Create a snapshot with a specific retention tag (`O`, `B`, `H`, `D`, `W`, `M`) |
| `sudo timeshift --restore` | Start the interactive CLI restore wizard |
| `sudo timeshift --restore --snapshot "ID"` | Restore a specific snapshot by its ID/timestamp |
| `sudo timeshift --delete --snapshot "ID"` | Delete a specific snapshot |
| `sudo timeshift --delete-all` | Delete all snapshots to free disk space |
| `sudo timeshift --check` | Run scheduled check (triggers cron snapshot if due) |

---

## 1. Creating Snapshots

### Create an On-Demand Snapshot
Run this before performing package upgrades, kernel upgrades, or editing critical configurations:
```bash
sudo timeshift --create --comments "Pre-upgrade backup before kernel update" --tags O
```

### Snapshot Tags Explained
Tags determine how Timeshift's retention policy applies to the snapshot:
- `O` : **On-demand** (Manual backup; will not be purged by automated schedule policies)
- `B` : **Boot** (Snapshot created at system boot)
- `H` : **Hourly**
- `D` : **Daily**
- `W` : **Weekly**
- `M` : **Monthly**

### Specify Snapshot Mode Explicitly
```bash
# Force RSYNC mode
sudo timeshift --create --rsync --comments "Manual RSYNC checkpoint"

# Force BTRFS mode (only on Btrfs systems)
sudo timeshift --create --btrfs --comments "Manual BTRFS checkpoint"
```

---

## 2. Listing & Inspecting Snapshots

To view all available snapshots and check which storage device holds your backup repository:
```bash
sudo timeshift --list
# Alias:
sudo timeshift --list-snapshots
```

**Example output:**
```text
Device : /dev/sda1
UUID   : 8a9b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d
Path   : /timeshift/snapshots/
Mode   : RSYNC

Index  Name                 Tags  Comments
-------------------------------------------------------------------------
0      2026-07-25_10-00-01  D     Daily backup
1      2026-07-26_14-30-00  O     Pre-upgrade backup before kernel update
```

### Checking Snapshot Disk Usage
By default, RSYNC snapshots are stored in `/timeshift/` on the target root partition or external backup drive:
```bash
# View overall disk space used by Timeshift snapshots
sudo du -sh /timeshift/

# Check individual snapshot sizes
sudo ls -lh /timeshift/snapshots/
```

---

## 3. Restoring Snapshots

### Interactive Restore (Recommended)
On headless servers, running `--restore` opens an interactive text wizard that lets you select the snapshot and confirm target partitions:
```bash
sudo timeshift --restore
```
1. Select the snapshot index from the list.
2. Confirm target root (`/`) device (e.g., `/dev/sda1`).
3. Accept the bootloader (GRUB) reinstallation prompt if asked.
4. Press `y` to confirm. The system will restore files and automatically reboot.

### Non-Interactive (Automated) Restore
If you know the exact snapshot name and target block device:
```bash
sudo timeshift --restore --snapshot "2026-07-26_14-30-00" --target /dev/sda1
```

### Skip GRUB Bootloader Reinstallation
If you only want to restore filesystem files without touching GRUB or MBR:
```bash
sudo timeshift --restore --snapshot "2026-07-26_14-30-00" --skip-grub
```

---

## 4. Deleting Snapshots & Disk Cleanup

### Delete a Specific Snapshot
To remove a single outdated snapshot:
```bash
sudo timeshift --delete --snapshot "2026-07-25_10-00-01"
```

### Delete All Snapshots
To completely wipe all snapshots and reclaim disk space:
```bash
sudo timeshift --delete-all
```

---

## 5. Headless Server Configuration (`/etc/timeshift/timeshift.json`)

On headless Linux servers without a graphical desktop, configure backup schedules, retention counts, and exclusion rules by editing the main configuration file:

```bash
sudo nano /etc/timeshift/timeshift.json
```

### Key Configuration Settings
```json
{
  "backup_device_uuid" : "your-disk-uuid-here",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "false",
  "include_btrfs_home" : "false",
  "stop_cron_log" : "true",
  "schedule_hourly" : "false",
  "schedule_daily" : "true",
  "schedule_weekly" : "false",
  "schedule_monthly" : "false",
  "schedule_boot" : "false",
  "count_hourly" : "5",
  "count_daily" : "5",
  "count_weekly" : "2",
  "count_monthly" : "1",
  "count_boot" : "5",
  "exclude" : [
    "/home/**",
    "/root/**",
    "/var/lib/mysql/**",
    "/var/lib/postgresql/**",
    "/var/lib/redis/**",
    "/var/log/**",
    "/tmp/**"
  ]
}
```

> **Important Exclusion Practice:**  
> Always ensure database storage directories (`/var/lib/mysql/**`, `/var/lib/postgresql/**`, `/var/lib/redis/**`) are listed under `"exclude"`. Restoring a filesystem snapshot over an active database can cause severe data corruption or transaction loss.

---

## 6. Practical Server Maintenance Workflows

### 1. Pre-Upgrade Safety Alias
Add a handy alias to your `~/.bashrc` to take a tagged checkpoint before running system updates:
```bash
# Alias to create an on-demand Timeshift snapshot before APT upgrade
alias safe-upgrade='sudo timeshift --create --comments "Pre-upgrade $(date +%F_%H-%M)" --tags O && sudo apt update && sudo apt upgrade -y'
```

### 2. Checking & Validating Cron Automation
Timeshift creates a cron job in `/etc/cron.d/timeshift-hour` or `/etc/cron.daily/timeshift`. You can manually trigger the schedule checker to test your setup:
```bash
sudo timeshift --check --verbose
```

### 3. Emergency Recovery from Live USB / Rescue Environment
If a kernel update or bad configuration prevents your server from booting:
1. Boot the server using an Ubuntu/Debian Live ISO or Rescue Mode.
2. Install Timeshift in the rescue environment:
   ```bash
   sudo apt update && sudo apt install timeshift -y
   ```
3. List available snapshots on your server's disk:
   ```bash
   sudo timeshift --list
   ```
4. Start the interactive restoration:
   ```bash
   sudo timeshift --restore
   ```
5. Select your broken system partition as the target, complete the restoration, and reboot into your working system.
