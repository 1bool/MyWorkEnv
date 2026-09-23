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

is_msys2()  { [[ "${ID:-}" == "msys2" ]]; }
is_wsl()    { grep -qi microsoft /proc/version 2>/dev/null; }
is_linux()  { [[ "$(uname -s)" == "Linux" ]] && ! is_wsl; }
is_macos()  { [[ "$(uname -s)" == "Darwin" ]]; }
is_debian() { [[ "${ID_LIKE:-}" == *debian* ]]; }
is_rhel()   { [[ "${ID_LIKE:-}" == *rhel* ]] || [[ "${ID_LIKE:-}" == *fedora* ]]; }

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

# Install lua-language-server (LuaLS) into ~/.local/bin/lua-ls/ and expose
# ~/.local/bin/lua-ls/bin on PATH for the current shell. The upstream release
# ships a self-contained bundle (launcher + main.lua + meta/locale) that must
# stay together, hence the dedicated directory instead of a bare symlink.
# Download URL: assets embed the version, so we resolve the latest tag first.
install_lua_ls() {
    local proxy="${GH_PROXY:-https://ghfast.top/}"
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
        case ":$PATH:" in *":$bindir:"*) ;; *) export PATH="$bindir:$PATH" ;; esac
        return 0
    fi
    rm -rf "$T"
    return 1
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
