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

# ! Adding verison 
# source ssh-tool.sh

# verlte() {
#     [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
# }

# if [verlte 2.5.7 2.5.6 && echo "yes" || echo "no" # no]; then

# fi

if [ ! -r $version -a ! -s $ConfigFile ] ; then
echo " Config file Setup Doesn't Exit...."
exit 11
fi

username=`grep -w "username" $ConfigFile | cut -d"=" -f2`

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

ssh_config='source $HOME/.ssh/.ssh-tool'

cp ./ssh-tool.sh ~/.ssh/.ssh-tool

if [ "$profile" = "unknown" ]; then
    echo 'Paste the information down below to your profile:'
    Echo_Color y "$ssh_config\n"
else
    if [ "$(grep -xn "$ssh_config" $profile)" != "" ]; then
        printf "$ssh_config\n" >> $profile
        Echo_Color g "You have updated your ssh-tool already installed in $profile!"
    else
        printf "$ssh_config\n" >> $profile
    fi
fi

#! what does this do?
if ! [ -f ~/.ssh/.ssh-tool ]; then
    printf "" >> ~/.ssh/.ssh-tool
fi

source $HOME/.ssh/.ssh-tool
read -p "Do you wish to create new profile? (Y|n)  " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
    then
    echo "Creating..."
    ssh-create    
fi

echo "Done installing! Enjoy by creating new terminal instance."