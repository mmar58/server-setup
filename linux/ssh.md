Enabling SSH (Secure Shell) in Kubuntu is straightforward. You just need to install the OpenSSH server package, start the service, and adjust your firewall if necessary.

Here is the step-by-step process using Konsole (the default terminal in Kubuntu):

Step 1: Install OpenSSH Server
Open Konsole (Ctrl + Alt + T) and update your package lists, then install the openssh-server package:

```Bash
sudo apt update
sudo apt install openssh-server
```
Step 2: Enable and Start the SSH Service
Enable the SSH daemon so it starts automatically upon boot and start it immediately:

```Bash
sudo systemctl enable --now ssh
```
You can verify that SSH is running with:

```Bash
sudo systemctl status ssh
```
Note: Look for active (running) in green text in the terminal output.

Step 3: Allow SSH Through the Firewall
If you have the Uncomplicated Firewall (UFW) enabled on Kubuntu, allow incoming SSH connections:

```Bash
sudo ufw allow ssh
```


Step 4: Find Your IP Address & Connect
To connect to your Kubuntu machine from another device, you need its IP address:

```Bash
hostname -I
```

From another computer on the same network, open a terminal or command prompt and connect using:

```Bash
ssh username@ip_address
```
(Replace username with your Kubuntu username and ip_address with the IP address retrieved above).