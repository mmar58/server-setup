Migrating an Express.js codebase to TypeScript incrementally is the smartest approach. It prevents you from having to halt new feature development while you rewrite the whole app. TypeScript has a built-in configuration specifically designed for this strategy.

Here is your step-by-step guide to slowly transitioning your backend without breaking your current production environment:

### Phase 1: The Initial Setup

**1. Install Dependencies**
You need the TypeScript compiler, an execution engine for development, and the type definition files for Node and Express.

```bash
npm install -D typescript @types/node @types/express tsx nodemon

```

**2. Initialize Configuration**
Generate your base `tsconfig.json` file.

```bash
npx tsc --init

```

**3. Configure `tsconfig.json` for Coexistence**
Update the generated file with these crucial settings. The absolute most important setting here is `"allowJs": true`, which tells the TypeScript compiler to accept both `.js` and `.ts` files side-by-side.

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "outDir": "./dist",
    "rootDir": "./src",     
    "allowJs": true,        
    "strict": false,        
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"]
}

```

*(Note: Adjust `"rootDir"` to wherever your main application code lives).*

---

### Phase 2: Update Build and Dev Scripts

Update your `package.json` to handle compilation and local development. Using `tsx` allows you to run `.ts` and `.js` files directly in development without having to constantly compile them to the `dist` folder.

```json
"scripts": {
  "start": "node dist/index.js",
  "dev": "nodemon --watch src --ext js,ts --exec tsx src/index.js",
  "build": "tsc"
}

```

---

### Phase 3: The Incremental Migration Strategy

Do not try to rename everything at once. Work from the "leaves" of your application tree up to the "trunk" (the main server file).

**1. Start with Utility Functions (The Leaves):**
Pick an isolated file that has no dependencies (e.g., a math helper or a string formatter). Rename it from `utils.js` to `utils.ts`.
**2. Add Basic Types:**
Fix any immediate errors by adding types to function parameters and return values. If you get completely stuck on a complex type, you can temporarily use `any`, but try to avoid it.
**3. Move to Middlewares & Models:**
Once your utilities are typed, move to your database schemas, helper classes, or custom Express middlewares.
**4. Controllers & Routes:**
Next, tackle your business logic and route definitions. This is where you'll heavily use the `Request` and `Response` types from `@types/express`.
**5. The Entry Point (The Trunk):**
Finally, rename your main `index.js` or `app.js` to `.ts`.

---

### Phase 4: Tightening the Screws

Months down the line, once every single file in your project ends in `.ts` and compiles successfully, you should enforce TypeScript's true power to keep your codebase safe.

* **Disable JS:** Change `"allowJs": false` in your `tsconfig.json` to ensure no new JavaScript files accidentally sneak into the project.
* **Enable Strict Mode:** Change `"strict": true`. This will cause a new wave of errors, but it is necessary. It forces you to handle potential `undefined` or `null` values and forbids implicit `any` types, giving you complete type safety.