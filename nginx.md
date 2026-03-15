# Nginx Cheat Sheet

Nginx is a high-performance web server and reverse proxy. This guide covers two common use cases: serving a domain from static files and proxying a domain to a running application on a port.

---

## Installation

```bash
sudo apt update
sudo apt install nginx -y
```

Check status:
```bash
sudo systemctl status nginx
```

---

## Config File Location

| Path | Description |
| :--- | :--- |
| `/etc/nginx/nginx.conf` | Main config file |
| `/etc/nginx/sites-available/` | Store your site configs here |
| `/etc/nginx/sites-enabled/` | Symlinks to active configs |

> **Tip:** Create your config in `sites-available/`, then symlink it to `sites-enabled/` to activate it.

---

## 1. Serving a Domain from Static Files

Use this when your site is a static build (e.g. HTML/CSS/JS output from Vite, Next.js export, etc.).

### Create the config

```bash
sudo nano /etc/nginx/sites-available/games.anzdevelopers.com
```

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name games.anzdevelopers.com www.games.anzdevelopers.com;

    root /var/www/games.anzdevelopers.com;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 2d;
        add_header Cache-Control "public, no-transform";
    }
    location ~* \.(js|css)$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
```

> **Note:** The `try_files` fallback to `/index.html` is important for Single Page Applications (SPAs) so that client-side routing works correctly.

### Set up the static files directory

```bash
sudo mkdir -p /var/www/anzdevelopers.com
sudo chown -R $USER:$USER /var/www/anzdevelopers.com

# Copy your build output here, e.g.:
cp -r ./dist/* /var/www/anzdevelopers.com/
```

---

## 2. Serving a Domain from a Port (Reverse Proxy)

Use this when you have a Node.js (or any other) app running on a local port (e.g. `3000`) and want Nginx to forward traffic to it.

### Create the config

```bash
sudo nano /etc/nginx/sites-available/api.anzdevelopers.com
```

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name games.anzdevelopers.com;

    location / {
        proxy_pass http://localhost:9000;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

> **Note:** The `Upgrade` and `Connection` headers are needed for WebSocket support (e.g. Socket.io apps).

---

## Activating a Config

After creating your config in `sites-available/`, enable it:

```bash
# Create symlink to enable the site
sudo ln -s /etc/nginx/sites-available/games.anzdevelopers.com /etc/nginx/sites-enabled/

# Test for syntax errors
sudo nginx -t

# Reload Nginx to apply changes
sudo systemctl reload nginx
```

---

## Adding HTTPS with Certbot (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain and auto-configure SSL certificate
sudo certbot --nginx -d games.anzdevelopers.com -d www.anzdevelopers.com -d anzdevelopers.com

# Certbot will automatically modify your nginx config to handle HTTPS and redirect HTTP → HTTPS
```

Auto-renewal is set up automatically. Test it with:
```bash
sudo certbot renew --dry-run
```

---

## Proxy Cache Configuration

Nginx can cache responses from your upstream app to reduce load and speed up repeat requests.

### Step 1 — Define a cache zone in `nginx.conf`

Open the main config:
```bash
sudo nano /etc/nginx/nginx.conf
```

Add this inside the `http { }` block (outside any `server` block):
```nginx
http {
    # ...existing config...

    # Define a shared cache zone
    # levels=1:2       → two-level directory structure
    # keys_zone=MY_CACHE:10m → name and size of key index (10MB ≈ 80,000 keys)
    # max_size=1g      → max disk space for cached responses
    # inactive=60m     → roemove items not accessed in 60 minutes
    # use_temp_path=off → write directly to cache dir (faster)
    proxy_cache_path /var/cache/nginx
        levels=1:2
        keys_zone=MY_CACHE:10m
        max_size=1g
        inactive=60m
        use_temp_path=off;
}
```

### Step 2 — Enable caching in your site config

```nginx
server {
    listen 80;
    server_name coinflipme.pro www.coinflipme.pro;

    # --- Cache skip rules ---
    # Don't cache if client sends no-cache header
    set $skip_cache 0;

    if ($http_cache_control = "no-cache") {
        set $skip_cache 1;
    }

    # Don't cache authenticated requests (cookie present)
    if ($http_cookie ~* ".") {
        set $skip_cache 1;
    }

    # Don't cache specific URL paths (API, admin, dynamic routes)
    if ($request_uri ~* "^/api/|^/admin/|^/socket.io/") {
        set $skip_cache 1;
    }

    location / {
        proxy_pass http://localhost:3000;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Enable cache (references the zone defined in nginx.conf)
        proxy_cache MY_CACHE;

        # Cache responses for these HTTP status codes
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404      1m;

        # Use the skip rules defined above
        proxy_cache_bypass $skip_cache;
        proxy_no_cache     $skip_cache;

        # Add a header so you can see if a response is HIT/MISS/BYPASS
        add_header X-Cache-Status $upstream_cache_status;

        # Serve stale cache if upstream is down (grace period)
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;

        # Lock: only one request fetches a new item; others wait for it
        proxy_cache_lock on;
    }

    # Static assets — cache at the browser level, skip proxy cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:3000;
        expires 30d;
        add_header Cache-Control "public, no-transform";
        proxy_no_cache 1;       # Don't store in Nginx proxy cache
        proxy_cache_bypass 1;   # Always fetch fresh from upstream
    }
}
```

### Cache skip cheat sheet

| Scenario | Config |
| :--- | :--- |
| Skip for all API routes | `if ($request_uri ~* "^/api/") { set $skip_cache 1; }` |
| Skip for logged-in users | `if ($http_cookie ~* "session=") { set $skip_cache 1; }` |
| Skip for POST requests | `if ($request_method = POST) { set $skip_cache 1; }` |
| Skip for query strings | `if ($query_string != "") { set $skip_cache 1; }` |
| Disable caching entirely for a location | `proxy_no_cache 1; proxy_cache_bypass 1;` |

### Checking cache status

The `X-Cache-Status` response header (added above) will tell you:

| Value | Meaning |
| :--- | :--- |
| `HIT` | Served from Nginx cache |
| `MISS` | Not in cache, fetched from upstream |
| `BYPASS` | Cache was skipped by a rule |
| `EXPIRED` | Cache existed but was stale |
| `STALE` | Stale cache served (upstream was down) |

```bash
# Test from terminal
curl -I https://coinflipme.pro | grep X-Cache-Status
```

### Purging the cache

```bash
# Clear all cached files
sudo rm -rf /var/cache/nginx/*

# Then reload Nginx
sudo systemctl reload nginx
```

> **Tip:** For selective/on-demand purging without clearing everything, consider the [nginx Cache Purge module](https://nginx.org/en/docs/http/ngx_http_proxy_module.html) or a tool like [nginx-cache-purge](https://github.com/FRiCKLE/ngx_cache_purge).

---

## Useful Commands

| Command | Description |
| :--- | :--- |
| `sudo nginx -t` | Test config for syntax errors |
| `sudo systemctl reload nginx` | Reload config without downtime |
| `sudo systemctl restart nginx` | Fully restart Nginx |
| `sudo systemctl enable nginx` | Start Nginx on boot |
| `sudo tail -f /var/log/nginx/access.log` | Watch access logs |
| `sudo tail -f /var/log/nginx/error.log` | Watch error logs |
