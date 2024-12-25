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

function setup_custom_configs() {
    local env=$1
    local custom_config_dir="$SCRIPT_DIR/config/custom"

    if [[ ! -d "$custom_config_dir" ]]; then
        echo -e "${YELLOW}No custom configurations directory found${NC}"
        return
    }

    echo -e "${BLUE}Setting up custom configurations...${NC}"

    # Process all files in the custom config directory
    find "$custom_config_dir" -type f -name "*-${env}" | while read -r config_file; do
        local basename=$(basename "$config_file")
        local target_name=${basename%-${env}}  # Remove the environment suffix
        local target_path="$HOME/.${target_name}"

        # Backup existing configuration
        if [[ -f "$target_path" ]]; then
            cp "$target_path" "${target_path}.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${YELLOW}Backed up existing ${target_name} configuration${NC}"
        fi

        # Copy new configuration
        cp "$config_file" "$target_path"
        echo -e "${GREEN}Installed custom configuration: ${target_name}${NC}"
    done
}

function setup_shell_config() {
    local env=$1
    local shell_type

    # Prompt user for shell selection
    echo -e "${CYAN}Select your preferred shell configuration:${NC}"
    echo "1) bash"
    echo "2) zsh"
    echo -e -n "${CYAN}Enter your choice (1-2):${NC} "
    read -r choice

    case $choice in
        1) shell_type="bash" ;;
        2) shell_type="zsh" ;;
        *)
            echo -e "${YELLOW}Invalid choice. Defaulting to bash${NC}"
            shell_type="bash"
            ;;
    esac

    # Search for configuration file using pattern
    local config_file=$(find "$SCRIPT_DIR/config/shell" -type f -name "*${shell_type}rc-${env}" 2>/dev/null | head -n 1)

    if [[ -f "$config_file" ]]; then
        local target_file
        case $shell_type in
            "bash") target_file=~/.bashrc ;;
            "zsh") target_file=~/.zshrc ;;
        esac

        # Backup existing configuration if it exists
        if [[ -f "$target_file" ]]; then
            cp "$target_file" "${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${YELLOW}Existing ${shell_type} configuration backed up${NC}"
        fi

        # Copy new configuration
        cp "$config_file" "$target_file"
        echo -e "${GREEN}${shell_type} configuration installed successfully${NC}"

        # Source the configuration
        source "$target_file"
    else
        echo -e "${RED}No ${shell_type} configuration found for ${env} environment${NC}"
    fi
}

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
    install_packages "pkg" "install -y" git ssh gnupg zsh

    # Setup shell configuration
    setup_shell_config "android"

    # Setup custom configurations
    setup_custom_configs "android"

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
    install_packages "sudo apt" "install -y" git ssh tree zip unzip curl wget gpg zsh

    # Setup shell configuration
    setup_shell_config "wsl"

    # Setup custom configurations
    setup_custom_configs "wsl"

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
