#!/usr/bin/env bash

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
        echo "$COLOR Wrong COLOR keyword!\033[0m" 
        ;;
        esac
        echo -e "$COLOR$2\033[0m"
    }

case $SHELL in
    *zsh )
    profile=~/.zshrc
    logout_profile=~/.zlogout
    ;;
    *bash )
    profile=~/.bashrc
    logout_profile=~/.bash_logout
    ;;
    * )
    Echo_Color r "Unknown shell, need to manually add config on your shell profile!!"
    profile='unknown'
    logout_profile='unknown'
    ;;
esac

ssh_config='# git account switch
source $HOME/.ssh/.ssh-tool'

cp ./ssh-tool.sh ~/.ssh/.ssh-tool

if [ "$profile" = "unknown" ]; then
    echo 'Paste the information down below to your profile:'
    Echo_Color y "$ssh_config\n"
else
    if [ "$(grep -xn "$ssh_config" $profile)" != "" ]; then
        Echo_Color g "You have already added ssh-tool in $profile !!\nOnly update your ssh-tool!"
    else
        printf "$ssh_config\n" >> $profile
    fi
fi

if ! [ -f ~/.ssh/.ssh-tool ]; then
    printf "" >> ~/.ssh/.ssh-tool
fi

source $HOME/.ssh/.ssh-tool
ssh-create
echo "Done!! Now can use! Enjoy~~~"
