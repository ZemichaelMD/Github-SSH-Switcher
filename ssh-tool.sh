#!/usr/bin/env bash
# To setup, add "$HOME/.ssh/ssh-tool.sh" to
# /etc/bash.bashrc or ~/.bashrc or ~/.zshrc

version="0.0.2"
PROFILE_DIR="$HOME/.ssh/profiles"

# Ensure profiles directory exists
mkdir -p "$PROFILE_DIR"

function ssh-which() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-which"
    return 1
  fi
  profiles=($(find "$PROFILE_DIR" -maxdepth 1 -type d -exec basename {} \; | tail -n +2))
  if [ ${#profiles[@]} -eq 0 ]; then
    echo "No profiles available to switch to.Would you like to create one? (Y/n)"
    read -r response
    if [[ $response =~ ^[Yy]$ ]]; then
      ssh-create
    fi
    return 1
  fi
  if [ ! -f "$PROFILE_DIR/.active" ]; then
    echo "No active profiles found! Would you like to select one? (Y/n)"
    read -r response
    if [[ $response =~ ^[Yy]$ ]]; then
      ssh-switch
    fi
  else
    active_profile=$(cat "$PROFILE_DIR/.active")
    echo "Active key: \"$active_profile\". Checking global name and email..."
    git config --list --global | grep -E 'user\.name|user\.email|github\.user|github\.token'
    echo "Authenticating active key \"$active_profile\" with GitHub..."
    ssh -T git@github.com
  fi
}

function ssh-list() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-list"
    return 1
  fi
  echo "Existing profiles:"
  find "$PROFILE_DIR" -maxdepth 1 -type d -exec basename {} \; | tail -n +2
}

function ssh-create() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-create"
    return 1
  fi
  printf "Enter a name for this SSH profile: "; read profile
  printf "Enter your name: "; read name
  printf "Enter your Git username: "; read username
  printf "Enter your Git user email: "; read email
  printf "Enter your Git private access token (Optional): "; read token

  profile_path="$PROFILE_DIR/$profile"
  echo "Generating new key for \"$profile\""

  # Clear any existing profile with the same name
  rm -rf "$profile_path"
  mkdir -p "$profile_path"

  # Generate the SSH key
  ssh-keygen -q -b 4096 -t rsa -f "$profile_path/id_rsa" -C "$email" -N ''

  # Create the .gitconfig for the profile
  printf "[user]\nemail = $email\nname = $username\n\n[github]\nuser = $username\ntoken = $token" > "$profile_path/.gitconfig"
  cp -f "$profile_path/.gitconfig" "$HOME/.gitconfig"

  # Update SSH config file
  {
    echo "Host github.com"
    echo "    User git"
    echo "    IdentityFile $profile_path/id_rsa"
  } >> "$HOME/.ssh/config"

  # Display the public key and instructions for GitHub
  echo "Your SSH public key has been generated. You can add it to GitHub with the following command:"
  cat "$profile_path/id_rsa.pub"

  echo "Copy the above key and follow these steps to add it to your GitHub account:"
  echo "1. Go to https://github.com and log in."
  echo "2. Navigate to Settings > SSH and GPG keys."
  echo "3. Click 'New SSH key'."
  echo "4. Paste your key into the 'Key' field."
  echo "5. Give it a Title (e.g., '$profile') and click 'Add SSH key'."

  echo "Files created in profile \"$profile\":"
  ls -p -a "$profile_path" | grep -v / | grep -v '^[.]/$'
  echo "$profile" > "$PROFILE_DIR/.active"
  ssh-which
}

function ssh-switch() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-switch"
    return 1
  fi

  # List available profiles
  profiles=($(find "$PROFILE_DIR" -maxdepth 1 -type d -exec basename {} \; | tail -n +2))
  if [ ${#profiles[@]} -eq 0 ]; then
    echo "No profiles available to switch to. Please create one first."
    return 1
  fi

  PS3="Please select a profile to switch to: "
  select profile in "${profiles[@]}"; do
    if [ -z "$profile" ]; then
      echo "Invalid selection! Please try again..."
    else
      profile_path="$PROFILE_DIR/$profile"
      if [ ! -f "$profile_path/id_rsa" ]; then
        echo "No profile \"$profile\" exists"
        return 2
      else
        echo "You have selected \"$profile\" profile"
        cp -f "$profile_path/.gitconfig" "$HOME/.gitconfig"
        cp -f "$profile_path/id_rsa*" "$HOME/.ssh/"
        cp -f "$profile_path/known_hosts" "$HOME/.ssh/known_hosts" 2>/dev/null
        echo "$profile" > "$PROFILE_DIR/.active"

        # Update SSH config for the active profile
        sed -i.bak "/^Host github.com$/,/^IdentityFile /d" "$HOME/.ssh/config"
        rm -f "$HOME/.ssh/config.bak"

        # Append the new SSH configuration
        {
          echo "Host github.com"
          echo "    User git"
          echo "    IdentityFile $profile_path/id_rsa"
        } >> "$HOME/.ssh/config"

        ssh-which
        break
      fi
    fi
  done
}

function ssh-remove() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-remove"
    return 1
  fi

  # List available profiles
  profiles=($(find "$PROFILE_DIR" -maxdepth 1 -type d -exec basename {} \; | tail -n +2))
  if [ ${#profiles[@]} -eq 0 ]; then
    echo "No profiles available to remove."
    return 1
  fi

  PS3="Please select a profile to remove: "
  select profile in "${profiles[@]}"; do
    if [ -z "$profile" ]; then
      echo "Invalid selection! Please try again..."
    else
      profile_path="$PROFILE_DIR/$profile"
      if [ ! -f "$profile_path/id_rsa" ]; then
        echo "No profile \"$profile\" exists"
        return 2
      else
        if [ "$profile" == "$(cat "$PROFILE_DIR/.active")" ]; then
          echo "Deleting active profile. Please switch profiles first."
          ssh-switch
        fi

        # Remove profile from SSH config
        sed -i.bak "/^Host github.com$/,/^IdentityFile $profile_path\/id_rsa/d" "$HOME/.ssh/config"
        rm -f "$HOME/.ssh/config.bak"

        # Delete the profile directory
        rm -rf "$profile_path"
        echo "Profile \"$profile\" removed."
        ssh-which
        break
      fi
    fi
  done
}

function ssh-clear() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-clear"
    return 1
  fi
  read -p "Are you sure you want to clear all SSH profiles? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Clearing SSH profiles..."
    rm -rf "$PROFILE_DIR"
    mkdir -p "$PROFILE_DIR"
    rm -rf "$HOME/.ssh/id_rsa*" "$HOME/.ssh/config" "$HOME/.gitconfig"
    echo "All profiles cleared."
    ssh-which
  else
    echo "Canceled!"
  fi
}
