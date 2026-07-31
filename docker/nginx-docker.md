To manage this cleanly, the best architectural approach is to use `docker-compose`. This allows you to define your internal network, isolate Adminer from direct public access, and map a local directory to the Nginx container for live configuration editing.

Here is the setup.

### 1. Project Structure

Create a directory for your project and set up the following file structure:

```text
your-project/
├── docker-compose.yml
└── nginx/
    └── conf.d/
        └── default.conf

```

### 2. The `docker-compose.yml`

This file defines both the Nginx and Adminer containers. We map port `80` to the host, but leave Adminer entirely internal so it can only be accessed via the Nginx reverse proxy.

```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      # Maps your local conf.d folder to the container
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
    depends_on:
      - adminer
    networks:
      - app-network

  adminer:
    image: adminer:latest
    restart: always
    # Adminer exposes port 8080 internally by default
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

```

### 3. The Nginx Configuration (`default.conf`)

This configuration listens on port 80 and intercepts traffic destined for `/admin`.

*Note: The trailing slashes on `/admin/` and `http://adminer:8080/` are critical. They tell Nginx to strip the `/admin` path before passing the request to Adminer, preventing 404 errors for static assets.*

```nginx
server {
    listen 80;
    server_name localhost;

    # Redirect /admin to /admin/ to ensure relative asset paths work in Adminer
    location = /admin {
        return 301 /admin/;
    }

    # Reverse proxy for Adminer
    location /admin/ {
        proxy_pass http://adminer:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Placeholder for your main application frontend (e.g., SvelteKit, Static HTML)
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        
        # If proxying to another container, comment out root/index and use:
        # proxy_pass http://your_frontend_container:port;
    }
}

```

### How to Run and Edit

1. Start the stack in detached mode:
```bash
docker compose up -d

```


2. Navigate to `http://localhost/admin` in your browser. You will see the Adminer login screen.
3. **Modifying the Config:** You can now open `./nginx/conf.d/default.conf` in your local code editor.
4. **Applying Changes:** Whenever you edit the config file, you don't need to rebuild the container. Just test and reload Nginx:
```bash
docker compose exec nginx nginx -t
docker compose exec nginx nginx -s reload

```