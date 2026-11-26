#!/bin/bash
# 固化 Windows 用户级环境变量（等价于 setx，但幂等、不受 1024 字符限制）
#
# 为什么放这里：/ucrt64/bin 等目录下是原生 Windows 程序，只认 Windows 进程环境，
# shell 里的变量（除非 export，且只影响该 shell 的子进程）传不进去。
# 所以这类开关要写进 HKCU\Environment，由所有新进程继承。
#
# 用法：bash scripts/win-env.sh
# 生效：新开的终端/进程；已在运行的进程不受影响（必要时注销重登）。

set -u

# ── 要固化的变量表（NAME=VALUE）──
VARS=(
    "PYTHONUTF8=1"       # Python UTF-8 模式：ucrt64 的 python 默认 stdout=gbk
)

if ! command -v powershell >/dev/null 2>&1; then
    echo "  ✗ 找不到 powershell，跳过 Windows 环境变量"
    exit 0
fi

PS=$(command -v powershell)

for kv in "${VARS[@]}"; do
    name=${kv%%=*}
    value=${kv#*=}
    cur=$("$PS" -NoProfile -Command "[Environment]::GetEnvironmentVariable('$name','User')" 2>/dev/null | tr -d '\r')
    if [ "$cur" = "$value" ]; then
        echo "  ✓ $name=$value（已存在）"
        continue
    fi
    if "$PS" -NoProfile -Command "[Environment]::SetEnvironmentVariable('$name','$value','User')" >/dev/null 2>&1; then
        echo "  ✓ $name=$value（已写入，新进程生效）"
    else
        echo "  ✗ $name 写入失败"
    fi
done
