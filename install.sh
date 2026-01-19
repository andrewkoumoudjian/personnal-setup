#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later

# Based on https://github.com/elithrar/dotfiles
# Sets up a macOS-based dev environment with OpenCode config.

# Configuration
BREW_PACKAGES=(age agg asciinema atuin bat bun cmake curl delta fd ffmpeg fzf gh gifski git glab go htop jj jq lua make mkcert neovim nmap node pipx pnpm python rbenv rcm ripgrep ruff ruby-build shellcheck stow tmux tree uv websocat wget wrk yarn zoxide zsh cloudflare/cloudflare/cloudflared)
CASKS=(raycast)
SSH_EMAIL="${SSH_EMAIL:-}"

# Colors - use fallbacks if tput unavailable
if command -v tput &>/dev/null && tput sgr0 &>/dev/null; then
    reset="$(tput sgr0)"
    red="$(tput setaf 1)"
    blue="$(tput setaf 4)"
    green="$(tput setaf 2)"
    yellow="$(tput setaf 3)"
else
    reset=""
    red=""
    blue=""
    green=""
    yellow=""
fi

# Error handling
trap 'ret=$?; [[ $ret -ne 0 ]] && printf "%s\n" "${red}Setup failed${reset}" >&2; exit $ret' EXIT
set -euo pipefail

# --- Helpers
print_success() {
    printf "%s %b\n" "${green}✔ success:${reset}" "$1"
}

print_error() {
    printf "%s %b\n" "${red}✖ error:${reset}" "$1"
}

print_info() {
    printf "%s %b\n" "${blue}ⓘ info:${reset}" "$1"
}

# ------
# Setup
# ------
cat <<EOF
${yellow}
Running...
 _           _        _ _       _
(_)_ __  ___| |_ __ _| | |  ___| |__
| | '_ \/ __| __/ _  | | | / __| '_ \\
| | | | \__ \\ || (_| | | |_\__ \\ | | |
|_|_| |_|___/\\__\\__,_|_|_(_)___/_| |_|

-----
- Sets up a macOS-based development machine.
- Safe to run repeatedly (checks for existing installs)
- Fork and adjust as needed
-----
${reset}
EOF

# Check environments
OS=$(uname -s 2>/dev/null)
INTERACTIVE=true
if [[ $- != *i* ]]; then
    INTERACTIVE=false
fi

print_info "Detected OS: ${OS}"
print_info "Interactive shell session: ${INTERACTIVE}"

if [ "${OS}" != "Darwin" ]; then
    print_error "This script currently supports macOS only."
    exit 1
fi

# Check for connectivity
if ! ping -q -t1 -c1 google.com &>/dev/null; then
    print_error "Cannot connect to the Internet"
    exit 1
else
    print_success "Internet reachable"
fi

# Ask for sudo
sudo -v &>/dev/null

# Set up repos directory
if [ ! -d "${HOME}/repos" ]; then
    mkdir -p "${HOME}/repos"
fi

# Install Homebrew
if ! command -v brew &>/dev/null; then
    print_info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    print_success "Homebrew installed"
else
    print_success "Homebrew already installed."
fi

# --- Homebrew
print_info "Installing Homebrew packages"
brew tap thoughtbot/formulae
for pkg in "${BREW_PACKAGES[@]}"; do
    print_info "Checking package ${pkg}"
    if ! brew list "${pkg}" &>/dev/null; then
        print_info "Installing ${pkg}"
        brew install --quiet "${pkg}"
    else
        print_success "${pkg} already installed"
    fi
done

if ! brew list reattach-to-user-namespace &>/dev/null; then
    brew install --quiet reattach-to-user-namespace
fi

print_info "Installing Homebrew Casks"
for pkg in "${CASKS[@]}"; do
    print_info "Checking package ${pkg}"
    if ! brew list --cask "${pkg}" &>/dev/null; then
        print_info "Installing ${pkg}"
        brew install --cask "${pkg}"
    else
        print_success "${pkg} already installed"
    fi
done

print_success "Homebrew packages"

# --- OpenCode dotfiles
print_info "Configuring OpenCode dotfiles"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -d "${SCRIPT_DIR}/.opencode" ]; then
    if [ -e "${HOME}/.opencode" ]; then
        print_info "Backing up existing .opencode directory"
        mv "${HOME}/.opencode" "${HOME}/.opencode.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    print_info "Copying OpenCode dotfiles"
    mkdir -p "${HOME}/.opencode"
    cp -a "${SCRIPT_DIR}/.opencode/." "${HOME}/.opencode/"
    print_success "OpenCode dotfiles installed"
else
    print_error ".opencode directory not found in repo"
    exit 1
fi

# --- SSH key
if [ "${INTERACTIVE}" = true ] && [ ! -f "${HOME}/.ssh/id_ed25519" ]; then
    if [ -z "${SSH_EMAIL}" ]; then
        read -r -p "SSH email for keygen (leave empty to skip): " SSH_EMAIL
    fi
    if [ -n "${SSH_EMAIL}" ]; then
        print_info "Generating new SSH key"
        mkdir -p "${HOME}/.ssh"
        chmod 700 "${HOME}/.ssh"
        ssh-keygen -t ed25519 -f "${HOME}/.ssh/id_ed25519" -C "${SSH_EMAIL}"
        print_info "Adding key to Keychain"
        ssh-add --apple-use-keychain "${HOME}/.ssh/id_ed25519"
    else
        print_info "Skipping SSH key generation"
    fi
fi

# --- Configure zsh
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    print_info "Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    if ! grep -q "$(command -v zsh)" /etc/shells; then
        command -v zsh | sudo tee -a /etc/shells
    fi
    chsh -s "$(command -v zsh)"
else
    print_success "oh-my-zsh already installed"
fi

# --- Install Atuin
if [ ! -d "${HOME}/.atuin" ]; then
    print_info "Installing Atuin"
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
else
    print_success "Atuin already installed"
fi

# --- Install nvm
if [ ! -d "${HOME}/.nvm" ]; then
    print_info "Installing nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | PROFILE=/dev/null bash
else
    print_success "nvm already installed"
fi

# --- Install uv
if ! command -v uv &>/dev/null; then
    print_info "Installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    print_success "uv already installed."
fi

# --- Install Rust
if ! command -v rustc &>/dev/null; then
    print_info "Installing Rust via rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
    print_success "Rust already installed."
fi

print_success "All done!"
