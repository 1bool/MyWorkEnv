#!/bin/sh
# tmux 状态栏守护进程（MSYS2/Windows 专用）—— 驻内存，状态栏刷新零 spawn
#
# 为什么需要它：MSYS2 下每次进程 spawn ~0.7s，且 tmux 3.7 的 #() 命令会在状态栏
# 重绘时反复重跑（实测 status-interval=30 下 12s 内仍跑了 15 次 ≈ 每秒跳一次）。
# 所以改成常驻循环：把 cpu/ram/load/uptime 算好后用 `tmux set-option` 直接写进
# catppuccin 的 *_text 选项（纯文本、无 #()），状态栏刷新时零 spawn、零抖动。
#
# 启动：~/.tmux.conf 里 `run -b '~/.tmux/scripts/statusd.sh'`（继承 $TMUX socket）。
# 单实例：按 socket 用 PID 文件防重复启动（prefix+r 重载不会叠加）。
# 退出：tmux server 退出时 `tmux set-option` 会失败 → break 循环 → trap 清锁。

set -u
export LANG=C LC_ALL=C

[ -n "${TMUX:-}" ] || exit 0

CACHE="$HOME/.cache/tmux-status"
mkdir -p "$CACHE" 2>/dev/null
sid=$(printf '%s' "${TMUX%%,*}" | tr '/:' '__')
LOCK="$CACHE/statusd.$sid.pid"
if [ -f "$LOCK" ]; then
  opid=$(cat "$LOCK" 2>/dev/null)
  [ -n "$opid" ] && kill -0 "$opid" 2>/dev/null && exit 0
fi
echo "$$" > "$LOCK"
trap 'rm -f "$LOCK"' EXIT
trap 'exit 0' INT TERM

pt=0; pi=0   # cpu 基线（跨轮采样，间隔约一个循环周期，比 1s 采样更平滑）

while :; do
  # cpu：/proc/stat 首行 "cpu user nice system idle"，idle 是第 4 个值（$5）。
  # 注意输出 %%：catppuccin 用 #{E:...} 二次展开 *_text，% 会被当成格式转义吃掉，
  # 所以要写 %% 让二次展开后还原成单个 %。
  read -r _ u n s i < /proc/stat
  t=$((u+n+s+i))
  if [ "$pt" -gt 0 ]; then
    dt=$((t-pt)); di=$((i-pi))
    [ "$dt" -gt 0 ] && cpu="$((100*(dt-di)/dt))%%" || cpu="0%%"
  else
    cpu="0%%"
  fi
  pt=$t; pi=$i

  # ram：/proc/meminfo 的 MemTotal-MemFree（MSYS2 的 buff/cache 恒为 0，与 free 同值）
  total=0; free=0
  while read -r k v _; do
    case "$k" in
      MemTotal:) total=$v ;;
      MemFree:) free=$v ;;
    esac
  done < /proc/meminfo
  [ "$total" -gt 0 ] && ram="$((100*(total-free)/total))%%" || ram="-"

  # load：读一次 ~10s，但在守护进程里，不阻塞状态栏
  read -r l1 l2 l3 _ < /proc/loadavg
  load="$l1, $l2, $l3"

  # uptime：只读 /proc/uptime（快）
  read -r s _ < /proc/uptime
  s=${s%%.*}
  d=$((s/86400)); h=$(((s%86400)/3600)); m=$(((s%3600)/60))
  up=""; [ "$d" -gt 0 ] && up="${d}d "; [ "$h" -gt 0 ] && up="${up}${h}h "; up="${up}${m}m"

  # 一次性写入 tmux（单次 spawn，不在状态栏刷新路径上）；
  # 失败说明 tmux server 已退出 → break 退出循环，trap 会清掉锁文件。
  if ! tmux set-option -g @catppuccin_cpu_text " $cpu" \; \
       set-option -g @catppuccin_ram_text " $ram" \; \
       set-option -g @catppuccin_load_text " $load" \; \
       set-option -g @catppuccin_uptime_text " $up" 2>/dev/null; then
    break
  fi

  sleep 30
done
