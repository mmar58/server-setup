# 🚀 Automating GitLab Authentication on Linux

Tired of typing your username and password every time you `git push` or `git pull`? This guide provides two methods to authenticate automatically with GitLab on Linux.

---

## 🔑 Method 1: SSH Keys (Recommended)

**Best for:** Security, professional workflows, and permanent setups.
This method uses cryptographic key pairs instead of passwords, offering superior security and convenience.

### Step 1: Check for Existing Keys
Before generating a new key, check if you already have one:
```bash
ls -al ~/.ssh
```
If you see `id_ed25519` or `id_rsa`, you can skip to **Step 3** or generate a new one.

### Step 2: Generate a New SSH Key
We'll use **ED25519**, which is more secure and faster than older RSA keys. Run this in your terminal:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```
- Press **Enter** to accept the default file location.
- Press **Enter** twice to skip the passphrase (unless you want extra security).

### Step 3: Add Key to SSH Agent
Ensure the SSH agent is running and add your key so you don't have to type the passphrase (if set) repeatedly:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### Step 4: Add Public Key to GitLab
1. **Copy** your public key to the clipboard:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   *(Select and copy the output starting with `ssh-ed25519`...)*

2. Log in to **GitLab** and go to **Preferences** (Click your avatar -> Edit profile/Preferences).
3. Select **SSH Keys** from the left sidebar.
4. Paste the key into the **Key** field and click **Add key**.

### Step 5: Test the Connection
Verify your setup:
```bash
ssh -T git@gitlab.com
```
- Type `yes` if prompted to verify host authenticity.
- You should see: *"Welcome to GitLab, @username!"*

### Step 6: Update Existing Repositories
If you previously cloned via HTTPS, switch them to SSH:
1. Go to your project folder.
2. Get the **SSH URL** from your GitLab project page (e.g., `git@gitlab.com:USERNAME/REPOSITORY.git`).
3. Update the remote URL:
   ```bash
   git remote set-url origin git@gitlab.com:USERNAME/REPOSITORY.git
   ```

---

## 📝 Method 2: HTTPS Credential Helper

**Best for:** Quick setups or if SSH is blocked/unfamiliar.
Git can remember your username and password so you don't have to type them every time.

### Option A: Cache (Temporary)
Stores credentials in memory for a short time (default 15 minutes). Good for public/shared computers.
```bash
git config --global credential.helper cache
# Optional: Set timeout to 1 hour (3600 seconds)
git config --global credential.helper 'cache --timeout=3600'
```

### Option B: Store (Permanent)
Saves your credentials in a plain-text file on disk. **Only use this on your personal private computer.**
```bash
git config --global credential.helper store
```
**How to use:**
1. Run a command like `git pull`.
2. Enter your username and password **one last time**.
3. Git saves them to `~/.git-credentials`.

---

## 🛠️ Troubleshooting

**Problem: "Permission denied (publickey)"**
- Ensure you are using the **SSH URL** (`git@gitlab.com...`), not HTTPS.
- Verify your key is added to the agent (`ssh-add -l`).
- Check if the public key is correctly added to your GitLab account.

**Problem: "Repository not found"**
- Check if you have access rights to the repository on GitLab.
- Verify you copied the SSH URL correctly.

**Problem: Still asking for password (SSH)?**
- You might have set a passphrase when creating the key. Use `ssh-agent` (Step 3) to handle it.