#!/usr/bin/env bash

# Status Colors
RED="\033[0;31m"      # Errors, critical failures
GREEN="\033[0;32m"    # Success, completion
YELLOW="\033[0;33m"   # Warnings, skipped operations
BLUE="\033[0;34m"     # Progress, ongoing operations
PURPLE="\033[0;35m"   # Information, optional steps
CYAN="\033[0;36m"     # Prompts, user input
NC="\033[0m"          # Reset color

SKIP_GIT=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function setup_common() {
    cd ~ || {
        echo -e "${RED}Failed to change to home directory${NC}"
        exit 1
    }
    mkdir -p .ssh
}

function setup_gpg() {
    chmod 700 ~/.gnupg
    if [[ -n "$(ls -A "$SCRIPT_DIR/secrets/gpg/")" ]]; then
        echo -e "${BLUE}Importing GPG keys...${NC}"
        gpg --import "$SCRIPT_DIR/secrets/gpg/public.asc"
        gpg --import "$SCRIPT_DIR/secrets/gpg/private.asc"
        chmod 600 ~/.gnupg/*
        echo -e "${GREEN}GPG keys imported successfully.${NC}"
    else
        echo -e "${YELLOW}No GPG keys found in secrets/gpg/${NC}"
    fi
}

function setup_ssh() {
    local env=$1
    cp "$SCRIPT_DIR/config/ssh/config-$env" ~/.ssh/config

    if [[ -n "$(ls -A "$SCRIPT_DIR/secrets/ssh/")" ]]; then
        cp "$SCRIPT_DIR/secrets/ssh/"* ~/.ssh/
        chmod 600 ~/.ssh/id_*
        chmod 644 ~/.ssh/*.pub
        echo -e "${GREEN}SSH keys imported successfully.${NC}"
    else
        echo -e "${YELLOW}No SSH keys found in secrets/ssh/${NC}"
    fi
}

function setup_git() {
    if [[ $SKIP_GIT -eq 1 ]]; then
        echo -e "${YELLOW}Skipping Git configuration${NC}"
        return
    fi

    if [[ ! -f ~/.gitconfig ]]; then
        echo -e -n "${PURPLE}Do you want to configure Git?${NC} (y/N) "
        read confirm_git
        if [[ ${confirm_git,,} != "y" ]]; then
            echo -e "${YELLOW}Skipping Git configuration${NC}"
            return
        fi

        echo -e -n "${CYAN}Enter your Git username:${NC} "
        read git_username
        echo -e -n "${CYAN}Enter your Git email:${NC} "
        read git_email

        template_path="$SCRIPT_DIR/config/git/.gitconfig-template"
        sed -e "s/{USERNAME}/$git_username/g" \
            -e "s/{EMAIL}/$git_email/g" \
            "$template_path" > ~/.gitconfig

        echo -e "${GREEN}Git configuration created successfully${NC}"
    else
        echo -e "${YELLOW}Git configuration already exists${NC}"
    fi
}

function install_packages() {
    local package_manager=$1
    local install_command=$2
    shift 2
    local commands=("$@")

    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            $package_manager $install_command "$cmd"
        fi
    done
}

function setup_android() {
    echo -e "${BLUE}Setting up Android environment...${NC}"
    pkg update && pkg upgrade -y

    # Create necessary directories
    mkdir -p ~/.shortcuts ~/logs ~/scripts

    # Copy configuration files
    cp "$SCRIPT_DIR/config/shell/.bashrc-android" ~/.bashrc
    source ~/.bashrc

    # Copy scripts for termux widget
    if [[ -n "$(ls -A "$SCRIPT_DIR/scripts/android/termux/")" ]]; then
        cp "$SCRIPT_DIR/scripts/android/termux/"* ~/.shortcuts/
        chmod +x ~/.shortcuts/*
        echo "Termux widget scripts installed"
    fi

    # Copy scripts
    if [[ -n "$(ls -A "$SCRIPT_DIR/scripts/android/utils/")" ]]; then
        cp "$SCRIPT_DIR/scripts/android/utils/"* ~/scripts/
        chmod +x ~/scripts/*
        echo "Termux utilities installed"
    fi

    # Install necessary packages
    install_packages "pkg" "install -y" git ssh gnupg

    # Setup GIT, SSH and GPG
    setup_git
    setup_ssh "android"
    setup_gpg

    echo -e "${GREEN}Android setup completed${NC}"
}

function setup_wsl() {
    echo -e "${BLUE}Setting up WSL2 environment...${NC}"
    sudo apt update && sudo apt upgrade -y

    # Create directories
    mkdir -p ~/scripts ~/logs ~/.ssh ~/projects ~/.gnupg

    # Copy scripts
    cp "$SCRIPT_DIR/scripts/wsl/"* ~/scripts

    # Install packages
    install_packages "sudo apt" "install -y" git ssh tree zip unzip curl wget gpg

    # Setup configuration files
    cat "$SCRIPT_DIR/config/shell/.bashrc-wsl" >> ~/.bashrc
    source ~/.bashrc

    # Setup GIT, SSH and GPG
    setup_git
    setup_ssh "wsl"
    setup_gpg

    echo -e "${GREEN}WSL2 (Debian-based system) setup completed${NC}"
}

# Main setup logic
setup_common

if [[ "$OSTYPE" == "linux-android" ]]; then
    setup_android
elif grep -q "WSL2" /proc/version; then
    setup_wsl
else
    echo -e "${RED}Unsupported environment. This script supports only Android (Termux) and WSL2.${NC}"
    exit 1
fi
