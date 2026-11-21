# ~/.config/shell/ai-models.sh — AI 模型与后端的唯一入口（bash/zsh 通用）
#
# 谁加载：~/.zshenv（zsh 全场景）+ ~/.bashrc（bash 含非交互）
# 内容分工：
#   1. 模型名   → 本文件（AI_MODEL_FLASH / AI_MODEL_PRO），两边共用一个来源
#   2. 后端档案 → ~/.config/shell/ai-backend.sh（本机私有，不入库，放 baseURL/key/proxy）
#   3. 后端选择 → 纯手动：ai-backend.sh 里的 AI_BACKEND 指定用哪个档案
#
# 切换后端：改 ~/.config/shell/ai-backend.sh 的 AI_BACKEND，或当前 shell 用 ai-switch B
# 查看现状：ai-status

AI_MODEL_FLASH='deepseek-v4-flash'
AI_MODEL_PRO='deepseek-v4-pro'
# OpenCode 侧 provider id，必须与 ~/.config/opencode/opencode.jsonc 中 providers 的键一致
OP_PROVIDER='anthropic'

# ── AI 工具运行环境 ──
# opencode / claude 在 Windows 上需要 bash 时，要求的是 Windows 形式路径。
# MSYS2 的 bash 即可，但 CONFIG_SITE 恒为 /etc/config.site，截断后得到的是
# /usr/bin/bash.exe 这种 POSIX 路径，原生 exe 解析不了 —— 必须用 cygpath 转成原生路径。
if [ -z "${OPENCODE_GIT_BASH_PATH:-}" ] && command -v cygpath >/dev/null 2>&1; then
    _oc_bash="$(cygpath -m /usr/bin/bash.exe 2>/dev/null || true)"
    if [ -n "$_oc_bash" ]; then
        OPENCODE_GIT_BASH_PATH="$_oc_bash"
        export OPENCODE_GIT_BASH_PATH
    fi
    unset _oc_bash
fi

# ── 应用后端档案（档案来自 ai-backend.sh）─────────────────────────────────
# 只清掉「本文件自己设过」的代理，不碰机器原有的全局代理配置。
_ai_backend_apply() {
    local name=${1:-} url key opus proxy suffix suffix_set
    [ -n "$name" ] || return 1
    eval "url=\${AI_BACKEND_${name}_URL:-}"
    eval "key=\${AI_BACKEND_${name}_KEY:-}"
    eval "opus=\${AI_BACKEND_${name}_OPUS_MODEL:-}"
    eval "proxy=\${AI_BACKEND_${name}_PROXY:-}"
    eval "suffix_set=\${AI_BACKEND_${name}_SUFFIX+set}"
    [ -n "$url" ] || return 1

    AI_BACKEND=$name
    export AI_BACKEND
    export ANTHROPIC_BASE_URL="$url"
    export ANTHROPIC_API_KEY="$key"

    # 模型后缀：先回无后缀基线，再按档案设置（网关用 [1m]，直连 API 一般留空）
    export ANTHROPIC_MODEL="${AI_MODEL_FLASH}"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="${AI_MODEL_FLASH}"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="${AI_MODEL_PRO}"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="${AI_MODEL_PRO}"
    if [ -n "$suffix_set" ]; then
        eval "suffix=\${AI_BACKEND_${name}_SUFFIX}"
        export ANTHROPIC_MODEL="${AI_MODEL_FLASH}${suffix}"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="${AI_MODEL_FLASH}${suffix}"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="${AI_MODEL_PRO}${suffix}"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="${AI_MODEL_PRO}${suffix}"
    fi
    if [ -n "$opus" ]; then
        export ANTHROPIC_DEFAULT_OPUS_MODEL="$opus"
    fi

    # AI 流量代理（claude / opencode 都读标准 HTTPS_PROXY）
    if [ -n "$proxy" ]; then
        export HTTPS_PROXY="$proxy" HTTP_PROXY="$proxy"
        export https_proxy="$proxy" http_proxy="$proxy"
        _AI_APPLIED_PROXY="$proxy"
    elif [ -n "${_AI_APPLIED_PROXY:-}" ]; then
        [ "${HTTPS_PROXY:-}" = "$_AI_APPLIED_PROXY" ] && unset HTTPS_PROXY
        [ "${HTTP_PROXY:-}" = "$_AI_APPLIED_PROXY" ] && unset HTTP_PROXY
        [ "${https_proxy:-}" = "$_AI_APPLIED_PROXY" ] && unset https_proxy
        [ "${http_proxy:-}" = "$_AI_APPLIED_PROXY" ] && unset http_proxy
        _AI_APPLIED_PROXY=''
    fi
}

# ── OpenCode（v2 配置里以 {env:OP_*} 引用）──
export OP_MODEL="${OP_PROVIDER}/${AI_MODEL_FLASH}"
export OP_BUILD="${OP_PROVIDER}/${AI_MODEL_FLASH}"
export OP_TITLE="${OP_PROVIDER}/${AI_MODEL_FLASH}"
export OP_PLAN="${OP_PROVIDER}/${AI_MODEL_PRO}"

# ── 加载本机后端档案并应用（纯手动，无探测）──
_ai_backend_file="${XDG_CONFIG_HOME:-$HOME/.config}/shell/ai-backend.sh"
if [ -f "$_ai_backend_file" ]; then
    . "$_ai_backend_file"
    _ai_backend_apply "${AI_BACKEND:-}" || true
fi
unset _ai_backend_file

# ── 辅助命令 ──
ai-status() {
    printf 'backend   %s\n' "${AI_BACKEND:-<未设置>}"
    printf 'baseURL   %s\n' "${ANTHROPIC_BASE_URL:-<未设置>}"
    printf 'proxy     %s\n' "${_AI_APPLIED_PROXY:-<直连>}"
    printf 'claude    model=%s haiku=%s sonnet=%s opus=%s\n' \
        "${ANTHROPIC_MODEL:-<空>}" "${ANTHROPIC_DEFAULT_HAIKU_MODEL:-<空>}" \
        "${ANTHROPIC_DEFAULT_SONNET_MODEL:-<空>}" "${ANTHROPIC_DEFAULT_OPUS_MODEL:-<空>}"
    printf 'opencode  model=%s build=%s plan=%s title=%s\n' \
        "${OP_MODEL:-<空>}" "${OP_BUILD:-<空>}" "${OP_PLAN:-<空>}" "${OP_TITLE:-<空>}"
}

# ai-switch <档案名> [-r]：当前 shell 立即切换；-r 顺带重启 opencode 服务
# 注意：不要在管道或 $(...) 里调用，子 shell 里的 export 不会回传到当前 shell。
ai-switch() {
    local target=${1:-} restart=0
    case "${2:-}" in -r|--restart) restart=1 ;; esac
    case "$target" in
        ""|-h|--help)
            printf 'usage: ai-switch <名称> [-r]\n可用档案：\n'
            local n
            for n in $(printf '%s' "${_AI_BACKEND_NAMES:-}"); do printf '  %s\n' "$n"; done
            return 0
            ;;
        *)
            if ! _ai_backend_apply "$target"; then
                printf '未知档案：%s（需在 ai-backend.sh 定义 AI_BACKEND_%s_URL/KEY）\n' "$target" "$target" >&2
                return 1
            fi
            ;;
    esac
    ai-status
    if [ "$restart" = 1 ] && command -v opencode >/dev/null 2>&1; then
        printf '重启 opencode 后台服务...\n'
        opencode service restart >/dev/null 2>&1 || true
    fi
}
