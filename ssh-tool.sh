#!/usr/bin/env bash
# To setup, add "$HOME/.ssh/ssh-tools.sh" to
# /etc/bash.bashrc or ~/.bashrc

function ssh-which() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-which"
    return 1
  fi
  if [ ! -f ~/.ssh/.active ]; then
    echo "No active profiles found!"
  else
    echo "Active key: \"$(cat ~/.ssh/.active)\". Checking global name and email... " 
    git config --list --global
    echo "Active key: \"$(cat ~/.ssh/.active)\". Authenticating with Github... " 
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
  cd $current
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
  ssh-keygen -q -b 4096 -t rsa -f ~/.ssh/$profile/id_rsa -C "$email" -N ''
  printf "[user]\nemail = $email\nname = $username\n\n[github]\nuser = $username\ntoken = $token" > ~/.ssh/$profile/.gitconfig
  printf "Files created:\n$(ls -p -a ~/.ssh/$profile | grep -v / | grep -v '^[\.]*/$')\n"
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
  profileNames=$(for f in */; do echo "${f%/*}"; done | sort -u )
  select lng in $profileNames
  do
    case $lng in
      $lng)
        if [ -z "$lng" ]
        then
          echo "Invalid! Please select again..."
        else
          if [ ! -f ~/.ssh/$lng/id_rsa ]; then
            echo "No profile \"$lng\" exists"
            return 2
          else
            cp -f ~/.ssh/$lng/.gitconfig ~/.gitconfig
            cp -f ~/.ssh/$lng/id_rsa* ~/.ssh
            cp -f ~/.ssh/$lng/known_hosts ~/.ssh/known_hosts
            echo $lng > ~/.ssh/.active
            ssh-which
            break
          fi
        fi
    esac
  done
  cd $current
}

function ssh-clear() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-clear"
    return 1
  fi
  read -p "Are you sure you want to clear ssh profile?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo "Removing..."
        printf "" > ~/.ssh/.gitconfig
        printf "" > ~/.ssh/.active
        printf "" > ~/.ssh/.ssh
        git config --global --unset user.name
        git config --global --unset user.email
        ssh-which
    else
        echo "Canceled!"
    fi
}

function ssh-remove() {
  if [ $# -ge 1 ]; then
    echo "[usage] ssh-remove"
    return 1
  fi
  current=$(pwd)
  cd ~/.ssh
  PS3="Please select profile to remove: "
  profileNames=$(for f in */; do echo "${f%/*}"; done | sort -u )
  select lng in $profileNames
  do
    case $lng in
      $lng)
        if [ -z "$lng" ]
        then
          echo "Invalid! Please select again..."
        else
          if [ ! -f ~/.ssh/$lng/id_rsa ]; then
            echo "No profile \"$lng\" exists"
            return 2
          else
          	
	    if [ $lng == $(cat ~/.ssh/.active) ]; then
		echo "Deleting active profile, Please switch profiles."
		ssh-switch
            	rm -rf ~/.ssh/$lng
	    else
		rm -rf ~/.ssh/$lng
		echo "Profile removed."
	    fi
            ssh-which
            break
          fi
        fi
    esac
  done
  cd $current
}