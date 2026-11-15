#!/bin/bash
# GitHub 加速代理探测
#   detect [--force]  输出当前最快可用的代理前缀（空串代表直连）
#   list   [--force]  输出每个候选的探测结果（耗时 + 状态）
#   json   [--force]  输出能代理 /releases/latest(JSON) 的最快代理
#
# 缓存：默认 30 分钟内复用上次结果，避免每次启动重复探测。
# 覆盖：GH_PROXY_LOCK=1 时不做探测，直接使用 GH_PROXY。
# 候选：GH_PROXY（若已设置）+ 默认列表 + 直连。

GH_PROXY_CANDIDATES_DEFAULT="${GH_PROXY_CANDIDATES:-https://gh-proxy.com/ https://ghproxy.net/ https://ghfast.top/}"
GH_PROXY_CACHE_TTL="${GH_PROXY_CACHE_TTL:-1800}"
# 用一个体积可控的 release 资源探测真实下载链路（原始下载/重定向最易被墙）
GH_PROXY_PROBE_URL="https://github.com/twpayne/chezmoi/releases/latest/download/chezmoi-windows-amd64.exe"
# 少数场景（如 get.chezmoi.io 的 real_tag）需要代理返回 releases/latest 的 JSON
GH_PROXY_JSON_PROBE_URL="https://github.com/twpayne/chezmoi/releases/latest"

gh_proxy_cache_file() {
    printf '%s/myworkenv/%s' "${XDG_CACHE_HOME:-$HOME/.cache}" "${1:-gh_proxy}"
}

gh_proxy_candidates() {
    local seen=" " c
    for c in ${GH_PROXY:-} $GH_PROXY_CANDIDATES_DEFAULT ""; do
        case "$seen" in *" [$c] "*) continue ;; esac
        seen="$seen[$c] "
        printf '%s\n' "$c"
    done
}

# 探测成功则输出耗时（秒），失败返回非 0
gh_proxy_probe() {
    curl -fsSL -r 0-2047 -o /dev/null -w '%{time_total}' \
        --connect-timeout 3 --max-time 8 "${1}${GH_PROXY_PROBE_URL}" 2>/dev/null
}

gh_json_probe() {
    local prefix="$1" tmp t
    tmp=$(mktemp 2>/dev/null) || return 1
    t=$(curl -fsSL -H 'Accept: application/json' -o "$tmp" -w '%{time_total}' \
        --connect-timeout 3 --max-time 8 "${prefix}${GH_PROXY_JSON_PROBE_URL}" 2>/dev/null) || {
        rm -f "$tmp"; return 1
    }
    grep -q '"tag_name"' "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    printf '%s' "$t"
}

# 参数：<cache 文件> <探测函数> <force|""> <verbose|"">
_gh_proxy_detect() {
    local cache="$1" probe="$2" force="$3" verbose="$4"
    if [ "${GH_PROXY_LOCK:-0}" = "1" ]; then
        printf '%s\n' "${GH_PROXY:-}"
        return 0
    fi

    local ts val now
    now=$(date +%s)
    if [ "$force" != "force" ] && [ -f "$cache" ]; then
        read -r ts val < "$cache"
        if [ -n "$ts" ] && [ $((now - ts)) -lt "$GH_PROXY_CACHE_TTL" ]; then
            [ "$verbose" = "verbose" ] && printf '  %-32s (cached)\n' "${val:-<direct>}"
            printf '%s\n' "$val"
            return 0
        fi
    fi

    local tmp i=0 prefix
    tmp=$(mktemp -d 2>/dev/null) || tmp="${TMPDIR:-/tmp}/gh_proxy.$$"
    mkdir -p "$tmp"
    while IFS= read -r prefix; do
        (
            t=$("$probe" "$prefix") && \
                printf '%s\t%s\n' "$t" "$prefix" > "$tmp/$i"
        ) &
        i=$((i + 1))
    done < <(gh_proxy_candidates)
    wait

    if [ "$verbose" = "verbose" ]; then
        while IFS=$'\t' read -r t prefix; do
            printf '  %-32s %ss\n' "${prefix:-<direct>}" "$t"
        done < <(cat "$tmp"/* 2>/dev/null | sort -n)
    fi

    # 一个都没探通（可能是断网）：不写缓存，回退到首个默认代理
    if [ -z "$(ls -A "$tmp" 2>/dev/null)" ]; then
        rm -rf "$tmp"
        printf '%s\n' "${GH_PROXY_CANDIDATES_DEFAULT%% *}"
        return 0
    fi

    val=$(cat "$tmp"/* 2>/dev/null | sort -n | head -1 | cut -f2-)
    rm -rf "$tmp"

    mkdir -p "$(dirname "$cache")" 2>/dev/null || true
    printf '%s\t%s\n' "$now" "$val" > "$cache" 2>/dev/null || true
    printf '%s\n' "$val"
}

gh_proxy_detect() {
    _gh_proxy_detect "$(gh_proxy_cache_file gh_proxy)" gh_proxy_probe "${1:-}" "${2:-}"
}

gh_json_proxy_detect() {
    _gh_proxy_detect "$(gh_proxy_cache_file gh_proxy_json)" gh_json_probe "${1:-}" "${2:-}"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    case "${1:-detect}" in
        detect) shift || true
                force=""; [ "${1:-}" = "--force" ] && force=force
                gh_proxy_detect "$force" "" ;;
        list)   gh_proxy_detect force verbose ;;
        json)   shift || true
                force=""; [ "${1:-}" = "--force" ] && force=force
                gh_json_proxy_detect "$force" "" ;;
        *)
            echo "usage: proxy.sh [detect|list|json] [--force]" >&2
            exit 2
            ;;
    esac
fi
