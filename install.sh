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
    # 与 dot_zshenv/.bashrc 保持一致：claude 也用 MSYS home 下的 .claude，
    # 否则首次安装时插件会装到 %USERPROFILE%\.claude，dotfiles 生效后看不到。
    export CLAUDE_CONFIG_DIR="$(cygpath -w "$HOME/.claude" 2>/dev/null || echo "$HOME/.claude")"
    # 不把 %USERPROFILE%\.local\bin 加入 PATH；工具统一装到 MSYS $HOME。
    # 配置国内镜像，避免下面装 just 时 pacman 走原始 repo.msys2.org
    setup_msys2_mirror
fi

if is_debian; then
    # 配置国内镜像，避免下面装 just 时 apt 走原始 archive.ubuntu.com
    setup_debian_mirror
fi

# curl is needed for the proxy probe and the just fallback installer
if ! command -v curl >/dev/null 2>&1; then
    if is_debian; then
        sudo apt-get update -qq && sudo apt-get -y install curl
    elif is_rhel; then
        sudo dnf -y install curl
    fi
fi

# Pick the fastest working GitHub proxy (cached, see scripts/proxy.sh)
if command -v curl >/dev/null 2>&1; then
    export GH_PROXY="$(bash scripts/proxy.sh detect)"
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

# Run just install (all steps, idempotent)
exec just install
