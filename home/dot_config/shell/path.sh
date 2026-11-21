# ~/.config/shell/path.sh — 所有 PATH 增量的唯一位置
#
# 加载点（3 处，都是为绕开各 shell 的加载规则）：
#   ~/.zshenv   zsh 全场景（含非登录/非交互）
#   ~/.bashrc   bash 交互（见 .profile 的登录链）
#   ~/.zprofile 登录 zsh —— MSYS2 的 /etc/zprofile 会重置 PATH，必须在它之后再补一次
#
# 重复 source 安全：已存在的目录不会重复追加。
# 加新路径只改本文件一行。

_path_add() {
    [ -n "${1:-}" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

# 注意：不把 %USERPROFILE%\.local\bin 加入 PATH。
# claude/chezmoi/opencode/win32yank 等统一装到 MSYS $HOME，避免旧副本抢先。

# MSYS2 自带命令（zsh 从 Windows 直接拉起时 PATH 可能没有 /usr/bin）
_path_add /usr/bin

# opencode 官方安装/升级目录（install.sh 与 upgrade --method curl 都落这里）
_path_add "$HOME/.opencode/bin"

# 本地工具
_path_add "$HOME/.local/bin"
_path_add "$HOME/.local/bin/lua-ls/bin"

# mc-studio CLI
_path_add "$HOME/mc-studio/bin"

# MSYS2 系统守护进程（unfsd 等）
if [ -n "${MSYSTEM_PREFIX:-}" ] && [ -d "${MSYSTEM_PREFIX}/sbin" ]; then
    _path_add "${MSYSTEM_PREFIX}/sbin"
fi

export PATH
unset -f _path_add
