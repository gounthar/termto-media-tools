#!/usr/bin/env bash

# Check if 'silicon' is installed, and install it if not.
# Works on WSL2/Ubuntu. Tries apt, then cargo (Rust).

set -e

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Checking if 'silicon' is installed..."
if command_exists silicon; then
    echo "'silicon' is already installed."
    exit 0
fi

echo "'silicon' not found. Attempting to install..."

# Try apt
if command_exists apt; then
    if apt-cache show silicon >/dev/null 2>&1; then
        echo "Installing 'silicon' via apt..."
        sudo apt update
        sudo apt install -y silicon
        if command_exists silicon; then
            echo "'silicon' installed successfully via apt."
            exit 0
        else
            echo "Failed to install 'silicon' via apt."
        fi
    fi
fi

# Try cargo (Rust)
if command_exists cargo; then
    echo "Preparing to install 'silicon' via cargo..."
    if command_exists apt; then
        echo "Installing build dependencies (build-essential, pkg-config, libfontconfig1-dev, libxcb-render0-dev, libxcb-shape0-dev, libxcb-xfixes0-dev, libharfbuzz-dev, libfreetype6-dev)..."
        sudo apt update
        sudo apt install -y build-essential pkg-config libfontconfig1-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev libharfbuzz-dev libfreetype6-dev
    fi
    echo "Installing 'silicon' via cargo..."
    cargo install silicon
    if command_exists silicon; then
        echo "'silicon' installed successfully via cargo."
        exit 0
    else
        echo "Failed to install 'silicon' via cargo."
    fi
fi

echo "Could not install 'silicon' automatically."
echo "Please install Rust (https://rustup.rs) and run: cargo install silicon"
exit 1
