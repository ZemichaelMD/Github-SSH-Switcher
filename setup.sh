#!/usr/bin/env bash

# Ensure script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo privileges"
    exit 1
fi

# make sure the user is in the admin group
if ! groups $SUDO_USER | grep -q admin; then
    usermod -aG admin $SUDO_USER
fi

# Source the ssh-tool.sh to access its functions and variables
source ./ssh-tool.sh

function Echo_Color(){
    case $1 in
        r* | R* )
        COLOR='\033[0;31m'
        ;;
        g* | G* )
        COLOR='\033[0;32m'
        ;;
        y* | Y* )
        COLOR='\033[0;33m'
        ;;
        b* | B* )
        COLOR='\033[0;34m'
        ;;
        *)
        COLOR='\033[0m' # Default color
        echo -e "$COLOR Wrong COLOR keyword!"
        return
        ;;
    esac
    echo -e "$COLOR$2\033[0m"
}

ConfigFile="$HOME/.ssh/config"

# Create .ssh directory with proper permissions if it doesn't exist
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
fi

# Ensure proper ownership and permissions for .ssh directory and contents
chown -R $SUDO_USER:$(id -gn $SUDO_USER) "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Create the SSH tool file if it doesn't exist
if [ ! -f $HOME/.ssh/ssh-tool.sh ]; then
    touch $HOME/.ssh/ssh-tool.sh
fi

# Copy ssh-tool.sh to .ssh with proper permissions
cp ./ssh-tool.sh $HOME/.ssh/ssh-tool.sh
chown $SUDO_USER:$(id -gn $SUDO_USER) $HOME/.ssh/ssh-tool.sh
chmod 700 $HOME/.ssh/ssh-tool.sh

# Ensure profiles directory exists with proper permissions
mkdir -p "$PROFILE_DIR"
chown $SUDO_USER:$(id -gn $SUDO_USER) "$PROFILE_DIR"
chmod 700 "$PROFILE_DIR"

# Ensure .gitconfig has proper permissions
touch "$HOME/.gitconfig"
chown $SUDO_USER:$(id -gn $SUDO_USER) "$HOME/.gitconfig"
chmod 644 "$HOME/.gitconfig"

# Ensure SSH config has proper permissions
touch "$HOME/.ssh/config"
chown $SUDO_USER:$(id -gn $SUDO_USER) "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

# Check if the config file exists, if not create it
if [ ! -f "$ConfigFile" ]; then
    Echo_Color y "Config file doesn't exist. Setting up initial SSH config..."

    # Create the SSH config file with default settings for GitHub
    {
        echo "Host github.com"
        echo "    User git"
        echo "    IdentityFile $HOME/.ssh/your_profile/id_rsa" # Update this line dynamically later
    } > "$ConfigFile"
    chmod 600 "$ConfigFile"

    Echo_Color g "SSH config file created at $ConfigFile."
else
    Echo_Color y "Config file already exists at $ConfigFile."
    # permissions on existing config file
    chmod 600 "$ConfigFile"
fi

# check operating system
if [ "$(uname)" == "Darwin" ]; then
    # check if zsh is installed
    if ! command -v zsh &> /dev/null; then
        Echo_Color r "Zsh is not installed. Please install zsh first."
        # ask to install zsh
        read -p "Do you wish to install zsh? (Y|n)  " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # check if brew is installed
            if ! command -v brew &> /dev/null; then
                Echo_Color r "Homebrew is not installed. Please install homebrew first."
                # ask to install homebrew
                read -p "Do you wish to install homebrew? (Y|n)  " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # install homebrew
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi
                exit 1
            fi
            brew install zsh
        fi
        exit 1
    fi
    profile=$HOME/.zshrc
# if linux
elif [ "$(uname)" == "Linux" ]; then
    # check if bash is installed
    if ! command -v bash &> /dev/null; then
        Echo_Color r "Bash is not installed. Please install bash first."
        # ask to install bash
        read -p "Do you wish to install bash? (Y|n)  " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # install bash
            apt-get install bash
        fi
        exit 1
    fi
    profile=$HOME/.bashrc
# else
else
    Echo_Color r "Unknown operating system, please manually add config to your shell profile!!"
    exit 1
fi

# check if shell is set
if [ -z "$SHELL" ]; then
    Echo_Color r "Shell is not set. Please set your shell first."
    exit 1
fi

ssh_config='source $HOME/.ssh/ssh-tool.sh'

# Check and append to profile
if ! grep -qF "$ssh_config" "$profile"; then
    echo "$ssh_config" >> "$profile"
    chmod 644 "$profile"
    Echo_Color g "SSH tool has been installed in $profile!"
else
    Echo_Color y "SSH tool already exists in $profile."
fi

# Check if there are profiles already
profiles=($(find "$PROFILE_DIR" -maxdepth 1 -type d -exec basename {} \; | tail -n +2))
if [ ${#profiles[@]} -eq 0 ]; then
  echo "No profiles available to switch to. Would you like to create one? (Y/n)"
  read -r response
  if [[ $response =~ ^[Yy]$ ]]; then
    ssh-create
  fi
  exit 1
fi

# Prompt to create a new profile
read -p "Do you wish to create a new profile? (Y|n)  " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Creating..."
    ssh-create
fi

# permissions for SSH directory
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config

# permissions for current SSH keys
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

echo "Done installing! Enjoy SSH Tools for Github."
