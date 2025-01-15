# Git-SSH-Switcher

A tool for managing multiple GitHub SSH profiles easily and securely. This allows you to switch between different GitHub accounts and SSH keys with simple commands.

## Features

- Create and manage multiple SSH profiles with unique keys and configurations
- Easily switch between different GitHub accounts
- Secure storage of SSH keys with proper permissions
- Automatic configuration of Git user settings
- Simple command-line interface

## Installation
---
1. Clone this repository
2. Run the setup script:

```shell
sudo ./setup.sh
```
*Please use sudo for the setup. It will fail if you don't*

<br>

## Usage
---
### LIST ACCOUNTS
```shell
$ ssh-list
```

### SWITCH ACCOUNT
```shell
$ ssh-switch
```

### CREATE
```shell
$ ssh-create
```

### REMOVE
```shell
$ ssh-remove
```

### CLEAR
```shell
$ ssh-clear
```
