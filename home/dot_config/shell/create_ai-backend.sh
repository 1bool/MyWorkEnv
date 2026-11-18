# ~/.config/shell/ai-backend.sh — 后端档案（本机私有，首次由 chezmoi create_ 生成，之后不覆盖）
#
# 每台机器/每个网络环境可有不同档案；本文件不入库（放真实 key）。
# 由 ~/.config/shell/ai-models.sh 加载。切换后端只改 AI_BACKEND 一行。

# 用哪个档案（A / B / C ...）；临时覆盖：export AI_BACKEND=B
: "${AI_BACKEND:=A}"   # 外部先设置则优先（如 AI_BACKEND=B claude）
# 可选：全部档案名（供 `ai-switch` 提示用）
_AI_BACKEND_NAMES="A B"

# ── A：公司网关（内网 / VPN）──
AI_BACKEND_A_URL="https://token.molchip.com"
AI_BACKEND_A_KEY="sk-你的molchip-key"
AI_BACKEND_A_OPUS_MODEL="kimi-k3"   # 该网关最强档，占 opus 槽位
AI_BACKEND_A_SUFFIX="[1m]"          # 网关用 [1m] 表达 1M 上下文

# ── B：DeepSeek 直连（任何网络，无 kimi）──
AI_BACKEND_B_URL="https://api.deepseek.com/anthropic"
AI_BACKEND_B_KEY="sk-你的deepseek-key"
#AI_BACKEND_B_SUFFIX=""             # 直连若不吃 [1m]，取消注释置空

# ── C：经 AI PROXY（某些网络只有这条通）──
# AI PROXY 是 Anthropic 兼容端点 → 直接当 URL 用；是 HTTP(S) 正向代理 → 填 _PROXY，URL 写真实端点。
#AI_BACKEND_C_URL="https://api.deepseek.com/anthropic"
#AI_BACKEND_C_KEY="sk-你的deepseek-key"
#AI_BACKEND_C_PROXY="http://127.0.0.1:7890"
