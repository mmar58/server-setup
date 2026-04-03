# Linux terminal tips — human-readable sizes, safe deletions, and server commands

This note collects common Linux terminal commands for: viewing file sizes in human-readable form, safely deleting files (including "delete all" patterns), and useful server administration commands with full examples.

---

## View file sizes (human-readable)
- List files with human-readable sizes:
  - `ls -lh`  # long listing, human sizes (K/M/G)
- List sorted by size (largest first):
  - `ls -lSh`  # sort by size
- Show sizes of directories (summary):
  - `du -sh /path/to/dir`  # total size of directory
  - `du -h --max-depth=1 /path/to/dir`  # sizes of immediate children
- Find biggest files under a directory (preview, sorted):
  - `du -ah /path/to/dir | sort -h | tail -n 20`  # top 20 entries by size
- More precise/fast listing of large files (uses `find`):
  - `find /path/to/dir -type f -size +100M -printf '%s %p\n' | sort -rn | head -n 20`  # files >100MB, largest first
- Disk usage summary (filesystems):
  - `df -h`  # human-readable free/used space per mounted fs
  - `lsblk`  # block devices and mount points

---

## Deleting files safely (guidelines + commands)
Safety first: always preview what will be removed before running destructive commands. Prefer moving files to a temporary "trash" location so you can review before permanent deletion.

- Preview files before deletion with `find`:
  - `find /path/to/dir -type f -name '*.log' -mtime +30 -print`  # show logs older than 30 days
- Delete files with confirmation:
  - `rm -i file1 file2`  # ask before each removal
  - `rm -I *.tmp`  # ask once if many files
- Delete files without prompt (dangerous):
  - `rm file` or `rm -r dir` or `rm -rf dir`  # `-f` forces, `-r` recursive
- Safer workflow — move to a trash folder then delete after verification:
  - `mkdir -p /tmp/trash && mv /path/to/dir/target /tmp/trash/`  # move item to trash
  - Inspect `/tmp/trash` and if OK, `rm -rf /tmp/trash/*`
- Using `find` to delete (test first with `-print`):
  - Preview: `find /var/log -type f -name '*.log' -mtime +90 -print`
  - Delete:  `find /var/log -type f -name '*.log' -mtime +90 -delete`
- Delete all files in a directory (keeping directory itself):
  - `rm -rf /path/to/dir/*`  # removes non-hidden files
  - To include hidden files (bash):
    - `bash -c 'shopt -s dotglob && rm -rf /path/to/dir/*'`
  - Alternative (safer): empty directory by recreating it:
    - `rm -rf /path/to/dir && mkdir -p /path/to/dir && chown …` (use cautiously)
- WARNING: Never run `rm -rf /` or similar on production systems. Modern `rm` has `--preserve-root` by default to block `rm -rf /`. Always double-check your path and avoid running as root unless necessary.
- Use a recycle-tray approach with `trash-cli` (recommended for desktops/safer ops):
  - `sudo apt install trash-cli` (Debian/Ubuntu)
  - `trash-put file1`  # moves to user trash
  - `trash-list` and `trash-empty` to manage

---

## Deleting "everything" — strong warnings
If you mean "delete everything in the current directory":
- From the directory to clear:
  - `rm -rf ./*`  # removes non-hidden files
  - To include hidden: `bash -c 'shopt -s dotglob && rm -rf ./*'`
If you mean wiping the entire filesystem or machine: do not proceed without backups and explicit confirmation. Use specialized tools (disk wipe utilities) only when you truly intend to destroy data.

---

## Useful server administration commands (full examples)
Systemd services:
- `sudo systemctl status nginx`  # check service status
- `sudo systemctl restart nginx`  # restart service
- `sudo systemctl stop nginx` / `sudo systemctl start nginx`
- View service logs:
  - `sudo journalctl -u nginx -f`  # follow logs in real time
Logs and live tails:
- `sudo tail -n 200 /var/log/syslog`  # show last 200 lines
- `sudo tail -F /var/log/nginx/error.log`  # follow rotated logs safely
Process / resource monitoring:
- `top` or `htop`  # interactive process viewer (`htop` may need install)
- `ps aux | grep my_process`  # find process
Network and sockets:
- `ss -tuln`  # show listening sockets
- `sudo netstat -tulpen`  # older systems
Disk and memory:
- `df -h`  # filesystem disk usage
- `du -sh /var/www`  # directory size summary
- `free -h`  # memory usage
SSH / file transfer:
- `ssh user@host`  # login
- `scp file.tar.gz user@host:/path/`  # copy file to server
- `rsync -avz /local/path/ user@host:/remote/path/`  # efficient sync
Package updates (Debian/Ubuntu):
- `sudo apt update && sudo apt upgrade -y`
- RHEL/CentOS: `sudo yum update -y` or `sudo dnf update -y`
Container tooling:
- `docker ps -a`  # list containers
- `docker logs -f my_container`  # follow container logs
- `docker system df`  # docker disk usage
Crontab and scheduled jobs:
- `crontab -l`  # list current user's cron jobs
- `sudo crontab -l -u www-data`  # list another user
Backups and copies:
- `rsync -av --delete /source/ /backup/`  # mirror directories (test first!)
- Always test restore process before trusting backups.
Firewall and network config:
- `sudo ufw status verbose`  # on Ubuntu with UFW
- `sudo iptables -L -n -v`  # raw iptables rules
System info and uptime:
- `uname -a`  # kernel and architecture
- `uptime`  # load averages and uptime

---

## Quick safety checklist before destructive ops
- Preview what will be changed/deleted (`ls`, `find -print`).
- Work as an unprivileged user when possible; escalate with `sudo` only when needed.
- Keep recent backups; test restores.
- Use `--dry-run` on tools that support it (e.g., `rsync --dry-run`).
- For mass deletions: move to a temporary/trash folder first, then delete after verification.

---

## Short examples / cheatsheet
- Human-readable list: `ls -lh` 
- Sorted by size: `ls -lSh`
- Directory summary: `du -sh /var/log`
- Largest files: `find / -type f -size +100M -printf '%s %p\n' | sort -rn | head -n 20`
- Preview delete: `find /path -type f -name '*.bak' -mtime +30 -print`
- Delete old logs: `find /var/log -type f -name '*.log' -mtime +90 -delete`
- Empty directory (including hidden): `bash -c 'shopt -s dotglob && rm -rf /path/to/dir/*'`
- Restart service: `sudo systemctl restart myservice`
- Follow logs: `sudo journalctl -u myservice -f`

---

If you want, I can:
- Tailor this doc for a specific Linux distribution (Ubuntu, CentOS, Debian).
- Add example scripts (safe cleanup scripts, scheduled log rotation commands).
- Add a one-line safe-delete wrapper that moves files to a configurable trash folder.
