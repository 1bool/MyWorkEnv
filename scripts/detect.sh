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
