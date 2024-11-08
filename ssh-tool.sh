#!/usr/bin/env bash
# To setup, add "$HOME/.ssh/ssh-tool.sh" to
# /etc/bash.bashrc or ~/.bashrc or ~/.zshrc

version="0.0.1"

function ssh-which() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-which"
    return 1
  fi
  if [ ! -f ~/.ssh/.active ]; then
    echo "No active profiles found!"
  else
    echo "Active key: \"$(cat ~/.ssh/.active)\". Checking global name and email..."
    git config --list --global | grep -E 'user\.name|user\.email|github\.user|github\.token'
    echo "Active key: \"$(cat ~/.ssh/.active)\". Authenticating with GitHub..."
    ssh -T git@github.com
  fi
}

function ssh-list() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-list"
    return 1
  fi
  current=$(pwd)
  echo "Existing profiles: "
  cd ~/.ssh
  find * -type d
  cd "$current"
}

function ssh-create() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-create"
    return 1
  fi
  printf "Enter a name for this ssh git profile: "; read profile
  printf "Enter your name: "; read name
  printf "Enter your git username: "; read username
  printf "Enter your git user mail: "; read email
  printf "Enter your git private access token (Optional): "; read token

  echo "Generating new key for \"$profile\""
  rm -rf ~/.ssh/$profile &> /dev/null
  mkdir -p ~/.ssh/$profile &> /dev/null

  # Generate the SSH key
  ssh-keygen -q -b 4096 -t rsa -f ~/.ssh/$profile/id_rsa -C "$email" -N ''

  # Create the .gitconfig
  printf "[user]\nemail = $email\nname = $username\n\n[github]\nuser = $username\ntoken = $token" > ~/.ssh/$profile/.gitconfig
  cp -f ~/.ssh/$profile/.gitconfig ~/.gitconfig

  # Update SSH config file
  echo "Host github.com" >> "$HOME/.ssh/config"
  echo "    User git" >> "$HOME/.ssh/config"
  echo "    IdentityFile ~/.ssh/$profile/id_rsa" >> "$HOME/.ssh/config"

  # Display the public key and instructions for GitHub
  echo "Your SSH public key has been generated. You can add it to GitHub with the following command:"

  cat ~/.ssh/$profile/id_rsa.pub

  echo "Copy the above key and follow these steps to add it to your GitHub account:"
  echo "1. Go to https://gitHub.com and log in."
  echo "2. Navigate to Settings > SSH and GPG keys."
  echo "3. Click 'New SSH key'."
  echo "4. Paste your key into the 'Key' field."
  echo "5. Give it a Title (e.g., '$profile') and click 'Add SSH key'."

  printf "Files created:\n$(ls -p -a ~/.ssh/$profile | grep -v / | grep -v '^[\.]*/$')\n"
  echo "$profile" > ~/.ssh/.active
  ssh-which
}

function ssh-switch() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-switch"
    return 1
  fi
  current=$(pwd)
  cd ~/.ssh
  PS3="Please select profile to switch to: "
  profileNames=($(for f in */; do echo "${f%/}"; done | sort -u))
  select lng in "${profileNames[@]}"; do
    case $lng in
      "")
        echo "Invalid selection! Please try again..."
        ;;
      *)
        if [ ! -f ~/.ssh/$lng/id_rsa ]; then
          echo "No profile \"$lng\" exists"
          return 2
        else
          echo "You have selected \"$lng\" profile"
          cp -f ~/.ssh/$lng/.gitconfig ~/.gitconfig
          cp -f ~/.ssh/$lng/id_rsa* ~/.ssh
          cp -f ~/.ssh/$lng/known_hosts ~/.ssh/known_hosts
          echo "$lng" > ~/.ssh/.active

          # Update SSH config for the active profile
          sed -i.bak "/^Host github.com$/,/^IdentityFile /d" "$HOME/.ssh/config"
          rm -f "$HOME/.ssh/config.bak"

          # Append the new SSH configuration
          echo "Host github.com" >> "$HOME/.ssh/config"
          echo "    User git" >> "$HOME/.ssh/config"
          echo "    IdentityFile ~/.ssh/$lng/id_rsa" >> "$HOME/.ssh/config"

          ssh-which
          break
        fi
        ;;
    esac
  done
  cd "$current"
}

function ssh-remove() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-remove"
    return 1
  fi
  current=$(pwd)
  cd ~/.ssh
  PS3="Please select profile to remove: "
  profileNames=($(for f in */; do echo "${f%/}"; done | sort -u))
  select lng in "${profileNames[@]}"; do
    case $lng in
      "")
        echo "Invalid selection! Please try again..."
        ;;
      *)
        if [ ! -f ~/.ssh/$lng/id_rsa ]; then
          echo "No profile \"$lng\" exists"
          return 2
        else
          if [ "$lng" == "$(cat ~/.ssh/.active)" ]; then
            echo "Deleting active profile, please switch profiles first."
            ssh-switch
          fi

          # Remove profile from SSH config
          sed -i.bak "/^Host github.com$/,/^IdentityFile ~/.ssh\/$lng\/id_rsa/d" "$HOME/.ssh/config"
          rm -f "$HOME/.ssh/config.bak"

          # Remove the profile folder
          rm -rf ~/.ssh/$lng
          echo "Profile removed."
          ssh-which
          break
        fi
        ;;
    esac
  done
  cd "$current"
}

function ssh-clear() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-clear"
    return 1
  fi
  read -p "Are you sure you want to clear ssh profile? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing..."
    printf "" > ~/.ssh/.gitconfig
    printf "" > ~/.ssh/.active
    rm -rf ~/.ssh/id_rsa*

    # Clear SSH config
    sed -i.bak "/^Host github.com$/,/^IdentityFile /d" "$HOME/.ssh/config"
    rm -f "$HOME/.ssh/config.bak"

    # Unset global Git config for user name and email
    git config --global --unset user.name
    git config --global --unset user.email

    ssh-which
  else
    echo "Canceled!"
  fi
}
