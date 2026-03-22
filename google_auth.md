# How to Set Up Google Authenticator (2FA) for SSH Logins on a Linux Server

Securing your Linux server with Two-Factor Authentication (2FA) adds a critical layer of protection. This guide covers how to set up Google Authenticator using PAM (Pluggable Authentication Modules) to protect SSH connections on a Debian-based server (like Ubuntu).

---

## Step 1: Install the Google Authenticator PAM module

First, log into your server as the user you want to secure or as `root`. Run the following commands to install the necessary PAM library:

```bash
sudo apt update
sudo apt install libpam-google-authenticator -y
```

*(For CentOS/RHEL/AlmaLinux, you would use `sudo dnf install google-authenticator` or `epel-release` first).*

---

## Step 2: Initialize Google Authenticator for your User

Run the `google-authenticator` command **as the user who will be logging in via SSH**. Do not run this as root unless you are trying to secure the root login (which is generally not recommended).

```bash
google-authenticator
```

The setup script will ask you a series of questions:

1. **"Do you want authentication tokens to be time-based (y/n)?"**
   Press `y`.
   
   *A massive QR code will be generated in your terminal.*
   
2. **Scan the QR Code**
   Open the Google Authenticator app (or Authy, Bitwarden, etc.) on your phone, and scan the QR code displayed on the screen. Alternatively, you can use the secret key provided below the QR code to add it manually.

3. **Save your Backup Codes**
   Underneath the QR code and secret, you will be given several **emergency scratch codes**. Keep these somewhere safe (like a password manager). These are the only way to log in if you lose your phone!

4. **"Do you want me to update your "/home/username/.google_authenticator" file? (y/n)"**
   Press `y` to save your configuration.

5. **"Do you want to disallow multiple uses of the same authentication token? (y/n)"**
   Press `y` to restrict a token from being used multiple times (prevents replay attacks).

6. **"By default, a new token is generated every 30 seconds... Do you want to do so? (y/n)"**
   Press `n`. Usually, the default time drift settings are fine, unless you frequently suffer from poor time sync between your phone and the server.

7. **"If the computer that you are logging into isn't hardened against brute-force login attempts... Do you want to enable rate-limiting? (y/n)"**
   Press `y` to limit logins to 3 attempts every 30 seconds.

---

## Step 3: Configure PAM for SSH

Next, you need to tell PAM to use the Google Authenticator module for SSH connections.

Open the PAM SSH configuration file using a text editor like `nano`:

```bash
sudo nano /etc/pam.d/sshd
```

Add the following line to the file. Adding it at the bottom will prompt for the password first, then the verification code.

```bash
auth required pam_google_authenticator.so
```

*(Note: If you have issues and need a fallback, you can temporarily use `auth required pam_google_authenticator.so nullok` to allow users who haven't set up 2FA yet to log in normally. Only do this if you are enforcing it selectively).*

Save and close the file (`Ctrl+O`, `Enter`, `Ctrl+X` in nano).

---

## Step 4: Configure the SSH Daemon

You must now tell the SSH daemon to ask for this type of interactive authentication.

Open the `sshd_config` file:

```bash
sudo nano /etc/ssh/sshd_config
```

Find the following line and change its value to `yes` (if it's commented out with a `#`, remove the `#`):

```bash
KbdInteractiveAuthentication yes
```
*(On older versions of SSH, this directive might be called `ChallengeResponseAuthentication yes` instead. If you see it, set it to `yes`).*

Ensure that `UsePAM` is also set to `yes`, as it is required to route the login request through the module you just configured:

```bash
UsePAM yes
```

Save and close the file.

---

## Step 5: Restart the SSH Service

Apply your new SSH configuration by restarting the SSH service:

```bash
sudo systemctl restart sshd
```

*(Or `sudo systemctl restart ssh` on some distributions like Ubuntu).*

---

## Step 6: Test Your Configuration 🚨 IMPORTANT 🚨

**DO NOT close your current, active SSH connection!** 

Open a **new** terminal window and try to SSH into the server to make sure everything works. If you misconfigured something and you drop your current session, you could lock yourself out of the server permanently.

When you attempt to connect from the new terminal, the process should look like this:

```
ssh username@your_server_ip
Password:                   <-- Enter your standard Linux user password
Verification code:          <-- Enter the 6-digit code from Google Authenticator
```

If you are able to log in successfully, it is safe to close your initial, active SSH connection.

## Troubleshooting

- **I get "Permission denied (publickey)."**
  If you only authenticate using SSH keys and have `PasswordAuthentication no` set, SSH will bypass PAM normally. To force SSH to ask for *both* your SSH key and the Authenticator code, add this to the very bottom of `/etc/ssh/sshd_config`:
  
  ```bash
  AuthenticationMethods publickey,keyboard-interactive
  ```
- **"Verification code" isn't printing correctly/fails immediately.**
  Ensure your server clock is synced accurately via NTP (`sudo timedatectl set-ntp true`). If the server time is off by more than a minute, your TOTP codes will be universally rejected.

---

## Recovery: What to Do If You Lose Your Authenticator

If you lose your phone or the authenticator app, you can't generate the 6-digit code anymore. Here's how to recover access:

### Option 1: Use Your Emergency Scratch Codes

During setup (Step 2), you were given 5 one-time-use **emergency scratch codes**. If you saved them, simply use one of those codes in place of the 6-digit verification code when logging in via SSH:

```
Verification code: <paste one of your scratch codes here>
```

Each scratch code can only be used **once**.

### Option 2: Use Your Hosting Provider's Web Console (VNC Console)

This is the most common recovery method. Almost every VPS/cloud provider offers a browser-based console that connects **directly** to your server's terminal. This connection bypasses SSH entirely, so Google Authenticator is not involved.

**How to access it (general steps):**

1. Log in to your hosting provider's website (e.g., DigitalOcean, Vultr, Hetzner, Linode, AWS, etc.).
2. Navigate to your server/droplet/instance.
3. Look for a button like **"Console"**, **"VNC Console"**, **"Launch Console"**, or **"Web Console"**.
4. A terminal window will open in your browser. Log in with your Linux **username** and **password** — no 2FA is required here because this is a direct hardware-level connection, not SSH.

**Once you're logged in via the web console, disable 2FA:**

```bash
# 1. Remove the user's Google Authenticator config file
rm ~/.google_authenticator

# 2. Comment out or remove the PAM line
sudo nano /etc/pam.d/sshd
# Find and remove or comment out this line:
#   auth required pam_google_authenticator.so

# 3. Restart SSH
sudo systemctl restart sshd
```

You can now log in via SSH normally again. To re-enable 2FA, simply repeat the setup from **Step 2** onwards and scan the new QR code with your authenticator app.

> **Tip:** After re-enabling 2FA, immediately back up your new emergency scratch codes in a password manager (like Bitwarden or KeePass) so you don't get locked out again.
