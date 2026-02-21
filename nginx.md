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
sudo nano /etc/nginx/sites-available/yourdomain.com
```

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name yourdomain.com www.yourdomain.com;

    root /var/www/yourdomain.com;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
```

> **Note:** The `try_files` fallback to `/index.html` is important for Single Page Applications (SPAs) so that client-side routing works correctly.

### Set up the static files directory

```bash
sudo mkdir -p /var/www/yourdomain.com
sudo chown -R $USER:$USER /var/www/yourdomain.com

# Copy your build output here, e.g.:
cp -r ./dist/* /var/www/yourdomain.com/
```

---

## 2. Serving a Domain from a Port (Reverse Proxy)

Use this when you have a Node.js (or any other) app running on a local port (e.g. `3000`) and want Nginx to forward traffic to it.

### Create the config

```bash
sudo nano /etc/nginx/sites-available/yourdomain.com
```

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name yourdomain.com www.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;

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
sudo ln -s /etc/nginx/sites-available/yourdomain.com /etc/nginx/sites-enabled/

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
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Certbot will automatically modify your nginx config to handle HTTPS and redirect HTTP → HTTPS
```

Auto-renewal is set up automatically. Test it with:
```bash
sudo certbot renew --dry-run
```

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
