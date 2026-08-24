Here is how to get Zsh, Oh My Zsh (assuming "my gosh zsh" was a fun typo for Oh My Zsh!), auto-suggestions, and syntax highlighting set up on Kubuntu, along with making it your default shell.

Step 1: Install Zsh and Required Tools
Open Konsole (Ctrl + Alt + T) and update your packages, then install zsh, git, and curl:

```Bash
sudo apt update
sudo apt install zsh git curl -y
```

Step 2: Install Oh My Zsh
Run the official Oh My Zsh installation script:

```Bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
Note: During installation, the script may ask if you want to set Zsh as your default shell. You can type y and press Enter. If it doesn't ask, don't worry—we will set it manually in Step 5.

Step 3: Install Auto-Suggestions and Syntax Highlighting
Clone both plugin repositories directly into Oh My Zsh's custom plugins directory:

```Bash
# 1. Zsh Auto-suggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# 2. Zsh Syntax Highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

Step 4: Enable Plugins in .zshrc
Open your Zsh configuration file in a text editor (like nano or KDE's kate):

```Bash
nano ~/.zshrc
```
Find the line that starts with plugins=( (usually around line 70). Update it to include both plugins:

```Bash
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)
```
Save and exit (Ctrl + O, Enter, then Ctrl + X in Nano).

Reload your configuration:

```Bash
source ~/.zshrc
```
Step 5: Set Zsh as Default Shell
If Zsh isn't your default shell yet, set it using chsh:

```Bash
chsh -s $(which zsh)
```
Tip for Kubuntu/KDE users: Log out of your session and log back in (or restart your PC) for Konsole and system environment changes to take full effect.