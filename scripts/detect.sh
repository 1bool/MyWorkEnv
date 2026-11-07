# Platform detection — sourced by justfile recipes and install.sh
# Uses /etc/os-release (freedesktop.org standard)
#
# Mapping to chezmoi template variables:
#   is_msys2  ↔  .chezmoi.os == "windows"
#   is_wsl    ↔  .isWSL
#   is_linux  ↔  .chezmoi.os == "linux" (non-WSL)
#   is_macos  ↔  .chezmoi.os == "darwin"
#   is_debian ↔  .chezmoi.osRelease.idLike == "debian"
#   is_rhel   ↔  .chezmoi.osRelease.idLike == "rhel" or "fedora"

source /etc/os-release 2>/dev/null || true

# GitHub 代理探测（gh_proxy_detect 等）
[ -f "$(dirname "${BASH_SOURCE[0]}")/proxy.sh" ] && . "$(dirname "${BASH_SOURCE[0]}")/proxy.sh"

is_msys2()  { [[ "${ID:-}" == "msys2" ]]; }
is_wsl()    { grep -qi microsoft /proc/version 2>/dev/null; }
is_linux()  { [[ "$(uname -s)" == "Linux" ]] && ! is_wsl; }
is_macos()  { [[ "$(uname -s)" == "Darwin" ]]; }
is_debian() { [[ "${ID_LIKE:-}" == *debian* ]]; }
is_rhel()   { [[ "${ID_LIKE:-}" == *rhel* ]] || [[ "${ID_LIKE:-}" == *fedora* ]]; }

# cmd.exe 默认代码页是 936/GBK，UTF-8 中文会显示成乱码；交互式控制台切到 UTF-8
if is_msys2 && [ -t 1 ] && command -v chcp.com >/dev/null 2>&1; then
    chcp.com 65001 >/dev/null 2>&1 || true
fi

# Ensure the user's local bin dir (chezmoi, etc.) is on PATH.
# Recipes run in fresh shells that haven't sourced ~/.profile yet, so this
# makes `just <recipe>` work on a fresh machine before dotfiles are deployed.
ensure_user_bin() {
    local bin
    if is_msys2; then
        bin="$(cygpath -u "$USERPROFILE/.local/bin" 2>/dev/null || echo "$USERPROFILE/.local/bin")"
    else
        bin="$HOME/.local/bin"
    fi
    [ -d "$bin" ] || return 0
    case ":$PATH:" in
        *":$bin:"*) ;;
        *) export PATH="$bin:$PATH" ;;
    esac
}

# 解析 GitHub latest release 版本号（去掉 v 前缀）。优先用 release 资产的 302
# Location（不消耗 API 配额），失败再走 GitHub API（直连 + 代理）。
# 用法：github_latest_tag <owner/repo> [asset-filename]
github_latest_tag() {
    local repo="$1" file="$2" proxy tag u
    proxy="$(gh_proxy_detect 2>/dev/null)"
    if [ -n "$file" ]; then
        for u in "https://github.com/$repo/releases/latest/download/$file" \
                 "${proxy}https://github.com/$repo/releases/latest/download/$file"; do
            tag="$(curl -sI --connect-timeout 8 --max-time 20 "$u" 2>/dev/null \
                | grep -i '^location' | head -1 \
                | grep -oE '/releases/download/[^/]+' | sed 's|.*/||')"
            [ -n "$tag" ] && { printf '%s\n' "${tag#v}"; return 0; }
        done
    fi
    for u in "https://api.github.com/repos/$repo/releases/latest" \
             "${proxy}https://api.github.com/repos/$repo/releases/latest"; do
        tag="$(curl -fsSL --connect-timeout 5 --max-time 10 "$u" 2>/dev/null \
            | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
        [ -n "$tag" ] && { printf '%s\n' "${tag#v}"; return 0; }
    done
    return 1
}

# Install lua-language-server (LuaLS) into ~/.local/bin/lua-ls/ and expose
# ~/.local/bin/lua-ls/bin on PATH for the current shell. The upstream release
# ships a self-contained bundle (launcher + main.lua + meta/locale) that must
# stay together, hence the dedicated directory instead of a bare symlink.
# Download URL: assets embed the version, so we resolve the latest tag first.
install_lua_ls() {
    local proxy; proxy="$(gh_proxy_detect)"
    local os arch asset ext dest
    case "$(uname -s)" in
        Darwin) os=darwin ;;
        Linux)  os=linux ;;
        MINGW*|MSYS*|CYGWIN*) os=win32 ;;
        *) echo "  (unsupported OS for lua-language-server)"; return 1 ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64) arch=x64 ;;
        arm64|aarch64) arch=arm64 ;;
        *) echo "  (unsupported arch for lua-language-server)"; return 1 ;;
    esac
    case "$os" in
        win32) asset="win32-${arch}"; ext=zip ;;
        *)     asset="${os}-${arch}"; ext=tar.gz ;;
    esac
    # 资产文件名内含版本号（lua-language-server-<ver>-<asset>.<ext>），需先查 latest tag
    local ver=""
    local u
    for u in "https://api.github.com/repos/LuaLS/lua-language-server/releases/latest" "${proxy}https://api.github.com/repos/LuaLS/lua-language-server/releases/latest"; do
        ver="$(curl -fsSL --connect-timeout 5 --max-time 8 "$u" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
        [ -n "$ver" ] && break
    done
    [ -n "$ver" ] || { echo "  ✗ lua-language-server version check failed"; return 1; }
    dest="${LUALS_DIR:-$HOME/.local/bin/lua-ls}"
    # 已装且版本一致则跳过（幂等，避免每次重新下载）
    if [ -x "$dest/bin/lua-language-server" ] && [ -f "$dest/.version" ] && [ "$(cat "$dest/.version" 2>/dev/null)" = "$ver" ]; then
        return 0
    fi
    local url="${proxy}https://github.com/LuaLS/lua-language-server/releases/download/${ver}/lua-language-server-${ver}-${asset}.${ext}"
    local T; T=$(mktemp -d)
    if curl -fL --connect-timeout 30 --max-time 600 "$url" -o "$T/lua-ls.$ext"; then
        rm -rf "$dest"; mkdir -p "$dest"
        if [ "$ext" = tar.gz ]; then
            tar xzf "$T/lua-ls.$ext" -C "$dest"
        else
            unzip -qo "$T/lua-ls.$ext" -d "$dest"
        fi
        rm -rf "$T"
        local bindir="$dest/bin"
        [ -x "$bindir/lua-language-server" ] || [ -x "$bindir/lua-language-server.exe" ] || { echo "  ✗ lua-language-server binary missing"; return 1; }
        printf '%s' "$ver" > "$dest/.version"
        case ":$PATH:" in *":$bindir:"*) ;; *) export PATH="$bindir:$PATH" ;; esac
        return 0
    fi
    rm -rf "$T"
    return 1
}

# nvim lazy.nvim 插件目录（通过 nvim 自身查询 stdpath，兼容 Windows/MSYS）
nvim_lazy_dir() {
    command -v nvim >/dev/null 2>&1 || return 1
    local data
    data=$(nvim --headless -u NONE +'lua io.write(vim.fn.stdpath("data"))' +qa 2>/dev/null | tr -d '\r')
    [ -n "$data" ] || return 1
    case "$data" in
        [A-Za-z]:[\\/]*) data=$(cygpath -u "$data" 2>/dev/null || printf '%s' "$data") ;;
    esac
    printf '%s/lazy\n' "$data"
}

# 更新前把有本地改动的插件仓库 stash 掉，避免 lazy.nvim 因脏工作区跳过更新。
stash_dirty_nvim_plugins() {
    command -v git >/dev/null 2>&1 || return 0
    local lazy d name
    lazy=$(nvim_lazy_dir) || return 0
    [ -d "$lazy" ] || return 0
    for d in "$lazy"/*/; do
        d=${d%/}
        [ -d "$d/.git" ] || continue
        if ! git -C "$d" diff --quiet 2>/dev/null || ! git -C "$d" diff --cached --quiet 2>/dev/null; then
            name=${d##*/}
            if git -C "$d" stash push -q -m "myworkenv auto-stash $(date +%Y-%m-%d)" 2>/dev/null; then
                echo "  ! $name 有本地改动，已 stash（git stash list 可恢复）"
            else
                echo "  ! $name 有本地改动，stash 失败"
            fi
        fi
    done
}

# Configure apt to use domestic mirrors (idempotent). Same rationale as
# setup_msys2_mirror — must run before the first `apt-get` on a fresh machine.
# Handles both classic sources.list and deb822 ubuntu.sources (24.04+).
setup_debian_mirror() {
    is_debian || return 0
    for src in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do
        [ -f "$src" ] || continue
        sudo sed -i \
            -e 's|https\?://[^/]*archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' \
            -e 's|https\?://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' \
            "$src"
    done
}

# Configure pacman to use domestic mirrors (idempotent). Must run before the
# first `pacman -S` on a fresh machine — the default repo.msys2.org is very
# slow/unreachable from China. Called from install.sh (before installing just),
# bootstrap (before unzip/git), and packages (replaces the inline mirror block).
setup_msys2_mirror() {
    is_msys2 || return 0
    grep -q "^\[${MSYSTEM,,}\]" /etc/pacman.conf 2>/dev/null || \
        printf '[options]\nHoldPkg= pacman\nArchitecture= auto\nColor\nCheckSpace\nParallelDownloads= 5\nSigLevel= Required\nLocalFileSigLevel= Optional\n[%s]\nInclude= /etc/pacman.d/mirrorlist.mingw\n[msys]\nInclude= /etc/pacman.d/mirrorlist.msys\n' "${MSYSTEM,,}" > /etc/pacman.conf
    echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/$repo/' > /etc/pacman.d/mirrorlist.mingw
    echo 'Server = https://mirrors.ustc.edu.cn/msys2/mingw/$repo/' >> /etc/pacman.d/mirrorlist.mingw
    echo 'Server = https://mirror.nju.edu.cn/msys2/mingw/$repo/' >> /etc/pacman.d/mirrorlist.mingw
    echo 'Server = https://repo.msys2.org/mingw/$repo/' >> /etc/pacman.d/mirrorlist.mingw
    echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/msys/$arch/' > /etc/pacman.d/mirrorlist.msys
    echo 'Server = https://mirrors.ustc.edu.cn/msys2/msys/$arch/' >> /etc/pacman.d/mirrorlist.msys
    echo 'Server = https://repo.msys2.org/msys/$arch/' >> /etc/pacman.d/mirrorlist.msys
}
