# Publishing and Building SvelteKit Applications

SvelteKit apps can be built and deployed in various ways depending on the "adapter" you choose. The two most common adapters for traditional server setups are the **Node.js adapter** (for SSR and dynamic servers) and the **Static adapter** (for purely static HTML/CSS/JS files).

---

## 1. Node.js Build (`@sveltejs/adapter-node`)

Use this adapter if you want a standalone Node.js server that supports Server-Side Rendering (SSR) and dynamic API routes.

### Installation & Setup

1. Install the adapter:
   ```bash
   npm i -D @sveltejs/adapter-node
   ```

2. Update your `svelte.config.js`:
   ```javascript
   import adapter from '@sveltejs/adapter-node';

   /** @type {import('@sveltejs/kit').Config} */
   const config = {
       kit: {
           adapter: adapter({
               // default options are shown. On some platforms
               // these options are set automatically — see below
               out: 'build',
               precompress: false,
               envPrefix: '',
               polyfill: true
           })
       }
   };

   export default config;
   ```

### Building & Running

1. Build the project:
   ```bash
   npm run build
   ```
   *This creates a `build` directory containing your Node application.*

2. Run the application:
   ```bash
   # You only need the 'build' directory, 'package.json', and 'node_modules' on your server
   node build/index.js
   ```

### Configuring Environment Variables

When running the Node.js build, you can pass environment variables exactly like any other Node.js application.

```bash
# Inline variables
PORT=3000 HOST=0.0.0.0 node build/index.js

# Using a .env file (you can use dotenv, or pm2 env configs)
```

**Using PM2 (Recommended for Production):**
```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: "my-svelte-app",
    script: "build/index.js",
    env: {
      PORT: 3000,
      ORIGIN: "https://my-domain.com", // Required if dealing with cross-origin requests
      DATABASE_URL: "postgresql://..."
    }
  }]
}
```

---

## 2. Static Build (`@sveltejs/adapter-static`)

Use this adapter if your app doesn't need a dynamic server and can be pre-rendered into static HTML, CSS, and JS files. Perfect for Nginx, Apache, GitHub Pages, or S3.

### Installation & Setup

1. Install the adapter:
   ```bash
   npm i -D @sveltejs/adapter-static
   ```

2. Update your `svelte.config.js`:
   ```javascript
   import adapter from '@sveltejs/adapter-static';

   /** @type {import('@sveltejs/kit').Config} */
   const config = {
       kit: {
           adapter: adapter({
               pages: 'build',
               assets: 'build',
               fallback: '200.html', // Set to '200.html' or 'index.html' for SPA mode
               precompress: false,
               strict: true
           })
       }
   };

   export default config;
   ```

3. **Critical Step:** Tell SvelteKit to prerender the app. Create a `src/routes/+layout.js` (or `.ts`) file and add:
   ```javascript
   export const prerender = true;
   // export const ssr = false; // Add this ONLY if you want a pure Single Page Application (SPA)
   ```

### Building & Running

1. Build the project:
   ```bash
   npm run build
   ```
   *This generates a `build` directory filled entirely with static files.*

2. Serve the application:
   You can serve the `build` directory using Nginx, Apache, or any static file server like `serve`:
   ```bash
   npx serve build
   ```

### Configuring Environment Variables (Static)

Because a static build produces HTML/JS that runs purely in the browser, **dynamic environment variables cannot be read at runtime from the server**. 

Any environment variables must be injected **at build time**:
```bash
# Provide variables during the build process
VITE_API_URL=https://api.example.com npm run build
```

---

## 3. Environment Variables in SvelteKit (Best Practices)

SvelteKit provides built-in modules for handling environment variables. You should prefer these over `process.env`.

### Public vs Private
- **Public (`$env/*/public`):** Variables that begin with `PUBLIC_` (e.g., `PUBLIC_API_URL`). Safe to expose to the client browser.
- **Private (`$env/*/private`):** Any variable that does not start with `PUBLIC_`. These will **never** leak to the client-side code and can only be used in server-side files (like `+page.server.js` or `+server.js`).

### Static vs Dynamic
- **Static (`$env/static/*`):** Injected at **build time**. If the value changes, you must rebuild the app. Best for static builds (`adapter-static`) or variables that never change.
- **Dynamic (`$env/dynamic/*`):** Read at **run time**. The app reads the OS environment variables when the server starts. Best for Node.js builds (`adapter-node`) where you might have different `.env` files for staging and production without rebuilding the app.

**Examples:**
```javascript
// Server-only, evaluated at runtime (Node adapter only)
import { DATABASE_URL } from '$env/dynamic/private';

// Server-only, embedded at build time
import { API_KEY } from '$env/static/private';

// Client & Server, evaluated at runtime (Node adapter only)
import { env } from '$env/dynamic/public';
console.log(env.PUBLIC_API_URL);

// Client & Server, embedded at build time (Safe for Static adapter)
import { PUBLIC_GA_ID } from '$env/static/public';
```

## Other Tips

- **Handling CORS/Origins in Node:** When running the Node adapter behind a reverse proxy (like Nginx), SvelteKit might throw Cross-Site Request Forgery (CSRF) errors. Make sure to set the `ORIGIN` environment variable when running the app (e.g., `ORIGIN=https://example.com node build/index.js`).
- **`.env` Files in Production:** SvelteKit automatically loads variables from `.env` files during development and the build process. However, the Node adapter running via `node build` **does not** automatically load `.env` files out-of-the-box in production unless you pass them via your environment provider (like PM2, Docker, systemctl) or manually require a package like `dotenv`.
