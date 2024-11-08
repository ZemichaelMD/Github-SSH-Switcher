#!/usr/bin/env bash

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

# Check if the config file exists, if not create it
if [ ! -f "$ConfigFile" ]; then
    Echo_Color y "Config file doesn't exist. Setting up initial SSH config..."

    # Create the SSH config file with default settings for GitHub
    {
        echo "Host github.com"
        echo "    User git"
        echo "    IdentityFile ~/.ssh/your_profile/id_rsa" # Update this line dynamically later
    } > "$ConfigFile"

    Echo_Color g "SSH config file created at $ConfigFile."
else
    Echo_Color y "Config file already exists at $ConfigFile."
fi

case $SHELL in
    *zsh )
    profile=~/.zshrc
    ;;
    *bash )
    profile=~/.bashrc
    ;;
    * )
    Echo_Color r "Unknown shell, need to manually add config to your shell profile!!"
    exit 1
    ;;
esac

ssh_config='source $HOME/.ssh/ssh-tool.sh'

# Copy ssh-tool.sh to .ssh
cp ./ssh-tool.sh ~/.ssh/ssh-tool.sh

# Check and append to profile
if ! grep -qF "$ssh_config" "$profile"; then
    echo "$ssh_config" >> "$profile"
    Echo_Color g "SSH tool has been installed in $profile!"
else
    Echo_Color y "SSH tool already exists in $profile."
fi

# Create the SSH tool file if it doesn't exist
if [ ! -f ~/.ssh/ssh-tool.sh ]; then
    touch ~/.ssh/ssh-tool.sh
fi

source "$HOME/.ssh/ssh-tool.sh"

PROFILE_DIR="$HOME/.ssh/profiles"

# Ensure profiles directory exists
mkdir -p "$PROFILE_DIR"

# Check if there are profiles already
profiles=($(find "$PROFILE_DIR" -maxdepth 1 -type d -exec basename {} \; | tail -n +2))
if [ ${#profiles[@]} -eq 0 ]; then
  echo "No profiles available to switch to. Would you like to create one? (Y/n)"
  read -r response
  if [[ $response =~ ^[Yy]$ ]]; then
    ssh-create
  fi
  return 1
fi

# Prompt to create a new profile
read -p "Do you wish to create a new profile? (Y|n)  " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Creating..."
    ssh-create
fi

echo "Done installing! Enjoy SSH Tools for Github."
