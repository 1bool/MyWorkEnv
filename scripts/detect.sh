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
