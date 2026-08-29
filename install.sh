#!/bin/bash
# MyWorkEnv — bootstrap install of just, then run just install
set -euo pipefail

echo "=== MyWorkEnv ==="
cd "$(dirname "$(readlink -f "$0")")"

source scripts/detect.sh

# ── Environment setup ──
export PATH="$HOME/.local/bin:$PATH"

if is_msys2; then
    # chezmoi config isolation: each MSYS2 has its own config
    export XDG_CONFIG_HOME="$(cygpath -m "$HOME/.config" 2>/dev/null || echo "$HOME/.config")"
    # native Windows exes (chezmoi, etc.) live in USERPROFILE, needs Unix path
    export PATH="$(cygpath -u "$USERPROFILE/.local/bin" 2>/dev/null || echo "$USERPROFILE/.local/bin"):$PATH"
    # 配置国内镜像，避免下面装 just 时 pacman 走原始 repo.msys2.org
    setup_msys2_mirror
fi

if is_debian; then
    # 配置国内镜像，避免下面装 just 时 apt 走原始 archive.ubuntu.com
    setup_debian_mirror
fi

# Install just if not present
if ! command -v just &>/dev/null; then
    echo "Installing just..."
    if is_msys2; then
        pacman -S --noconfirm just 2>/dev/null || \
            curl -fsSL https://just.systems/install.sh | bash -s -- --to ~/.local/bin
    elif is_macos; then
        brew install just 2>/dev/null || \
            curl -fsSL https://just.systems/install.sh | bash -s -- --to ~/.local/bin
    elif is_debian; then
        sudo apt-get update -qq && sudo apt-get -y install just 2>/dev/null || \
            curl -fsSL https://just.systems/install.sh | bash -s -- --to ~/.local/bin
    elif is_rhel; then
        sudo dnf -y install just 2>/dev/null || \
            curl -fsSL https://just.systems/install.sh | bash -s -- --to ~/.local/bin
    else
        curl -fsSL https://just.systems/install.sh | bash -s -- --to ~/.local/bin
    fi
fi

# Migrate from old system (one-time)
just migrate 2>/dev/null || true

# Run just install (all steps, idempotent)
exec just install
