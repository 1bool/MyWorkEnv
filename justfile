# MyWorkEnv — task runner
#   just install   → idempotent, skips what's already there
#   just update    → upgrade everything
#   just <recipe>  → run a single step independently

set shell := ["bash", "-c"]

# GitHub 加速镜像前缀（国内直连慢/被墙）。环境变量 GH_PROXY 可覆盖。
# 关闭加速：把默认值改成空字符串 ""。
gh_proxy := env_var_or_default("GH_PROXY", "https://ghfast.top/")

default:
    @just --list --unsorted

install: prep bootstrap packages msys2 dotfiles fonts plugins claude-code gitmux
    @echo "=== MyWorkEnv installed ==="

update: bootstrap bootstrap-update dotfiles-update packages packages-update msys2 fonts-update plugins plugins-update claude-code claude-code-update gitmux-update
    @echo "=== MyWorkEnv updated ==="

# ── Prep: one-time system setup (passwordless sudo, WSL PATH fix) ──
prep:
    @echo "=== Prep ==="; \
    source scripts/detect.sh; \
    if is_msys2; then echo "  (MSYS2 — nothing to do)"; exit 0; fi; \
    command -v sudo >/dev/null 2>&1 || { echo "  ✗ sudo not found"; exit 1; }; \
    if [ -f "/etc/sudoers.d/nopass_for_$USER" ]; then echo "  ✓ passwordless sudo already set"; \
    else \
        echo "  → enabling passwordless sudo (enter password once)..."; \
        echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/nopass_for_$USER" >/dev/null && sudo chmod 0440 "/etc/sudoers.d/nopass_for_$USER" && echo "  ✓ passwordless sudo enabled"; \
    fi; \
    if is_wsl; then \
        if grep -q 'appendWindowsPath' /etc/wsl.conf 2>/dev/null; then echo "  ✓ /etc/wsl.conf already set"; \
        else printf '[interop]\nappendWindowsPath = false\n' | sudo tee -a /etc/wsl.conf >/dev/null && echo "  ✓ WSL: appendWindowsPath disabled (restart WSL to apply)"; \
        fi; \
    fi

# ── Bootstrap ──
bootstrap:
	@echo "=== Bootstrap ==="; \
	source scripts/detect.sh; \
	if is_msys2; then \
	    command -v unzip >/dev/null || pacman -S --noconfirm unzip; \
	    command -v git   >/dev/null || pacman -S --noconfirm git; \
	elif is_macos; then \
	    command -v unzip >/dev/null || brew install unzip; \
	    command -v git   >/dev/null || brew install git; \
	elif is_debian; then \
	    command -v unzip >/dev/null || { sudo apt-get update && sudo apt-get -y install unzip; }; \
	    command -v git   >/dev/null || { sudo apt-get -y install git; }; \
	elif is_rhel; then \
	    command -v unzip >/dev/null || sudo dnf -y install unzip; \
	    command -v git   >/dev/null || sudo dnf -y install git; \
	fi; \
	CHEZMOI_BIN=""; \
	if is_msys2; then CHEZMOI_BIN="$USERPROFILE/.local/bin/chezmoi"; \
	else CHEZMOI_BIN="$HOME/.local/bin/chezmoi"; fi; \
	if command -v chezmoi >/dev/null 2>&1 || [ -x "$CHEZMOI_BIN" ]; then echo "  ✓ chezmoi"; \
	else \
	    if is_msys2; then \
	        curl -fsSL --connect-timeout 30 --retry 3 get.chezmoi.io \
	          | sed "s|https://github.com/|{{ gh_proxy }}https://github.com/|g; s|curl -w '%{http_code}'|curl --http1.1 --connect-timeout 30 --speed-limit 1024 --speed-time 60 -w '%{http_code}'|g; s|-fsSL|-fL|g" \
	          | bash -s -- -b "$USERPROFILE/.local/bin"; \
	    else \
	        curl -fsSL --connect-timeout 30 --retry 3 get.chezmoi.io \
	          | sed "s|https://github.com/|{{ gh_proxy }}https://github.com/|g; s|curl -w '%{http_code}'|curl --http1.1 --connect-timeout 30 --speed-limit 1024 --speed-time 60 -w '%{http_code}'|g; s|-fsSL|-fL|g" \
	          | bash -s -- -b "$HOME/.local/bin"; \
	    fi; \
	    echo "  ✓ chezmoi installed"; \
	fi; \
	if is_msys2; then \
	    C="${USERPROFILE}/.config/chezmoi/chezmoi.toml"; \
	    mkdir -p "$(dirname "$C")"; \
	    grep -q '\[interpreters' "$C" 2>/dev/null || \
	        printf '[data]\n  isWSL = false\n[interpreters.sh]\n  command = "bash"\n[interpreters.bash]\n  command = "bash"\n' > "$C"; \
	fi

bootstrap-update:
    @echo "  chezmoi: checking..."; \
    source scripts/detect.sh; ensure_user_bin; \
    chezmoi upgrade && echo "    ✓ upgraded" || echo "    ✓ up to date"

# ── System packages ──
packages:
    @echo "=== Packages ==="; \
    source scripts/detect.sh; \
    if is_msys2; then \
        grep -q '^\[ucrt64\]' /etc/pacman.conf 2>/dev/null || \
            printf '[options]\nHoldPkg= pacman\nArchitecture= auto\nColor\nCheckSpace\nParallelDownloads= 5\nSigLevel= Required\nLocalFileSigLevel= Optional\n[%s]\nInclude= /etc/pacman.d/mirrorlist.mingw\n[msys]\nInclude= /etc/pacman.d/mirrorlist.msys\n' "${MSYSTEM,,}" > /etc/pacman.conf; \
        echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/$repo/' > /etc/pacman.d/mirrorlist.mingw; \
        echo 'Server = https://mirrors.ustc.edu.cn/msys2/mingw/$repo/' >> /etc/pacman.d/mirrorlist.mingw; \
        echo 'Server = https://mirror.nju.edu.cn/msys2/mingw/$repo/' >> /etc/pacman.d/mirrorlist.mingw; \
        echo 'Server = https://repo.msys2.org/mingw/$repo/' >> /etc/pacman.d/mirrorlist.mingw; \
        echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/msys/$arch/' > /etc/pacman.d/mirrorlist.msys; \
        echo 'Server = https://mirrors.ustc.edu.cn/msys2/msys/$arch/' >> /etc/pacman.d/mirrorlist.msys; \
        echo 'Server = https://repo.msys2.org/msys/$arch/' >> /etc/pacman.d/mirrorlist.msys; \
        pacman -Sy --noconfirm --needed; \
        pacman -S --noconfirm --needed $(grep -v '^#' packages/base.txt) $(grep -v '^#' packages/cygwin-msys.txt) || { echo "  ✗ pacman install failed — some packages missing"; exit 1; }; \
        if [ -n "${MINGW_PACKAGE_PREFIX:-}" ]; then \
            MINGW=""; \
            for pkg in $(grep -v '^#' packages/cygwin-mingw.txt); do \
                MINGW="$MINGW ${MINGW_PACKAGE_PREFIX}-$pkg"; \
            done; \
            [ -n "$MINGW" ] && pacman -S --noconfirm --needed -- $MINGW; \
        else \
            echo "  (MSYS — no MINGW_PACKAGE_PREFIX, skipping mingw packages)"; \
        fi; \
    elif is_macos; then \
        command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"; \
        brew install $(grep -h -v '^#' packages/base.txt packages/macos.txt) || { echo "  ✗ brew install failed — some packages missing"; exit 1; }; \
    elif is_debian; then \
        for src in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do \
            [ -f "$$src" ] && sudo sed -i \
                -e 's|http://[^/]*archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' \
                -e 's|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' \
                "$$src"; \
        done; \
        sudo apt-get update; \
        sudo apt-get -y install $(grep -h -v '^#' packages/base.txt packages/debian.txt) || { echo "  ✗ apt install failed — some packages missing"; exit 1; }; \
        pip config get global.index-url 2>/dev/null | grep -q tuna.tsinghua || pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple 2>/dev/null || true; \
        [ -f packages/pip.txt ] && for pkg in $(grep -v '^#' packages/pip.txt); do \
            command -v "$pkg" >/dev/null 2>&1 && continue; \
            pip install --user --break-system-packages "$pkg" || true; \
        done; \
    elif is_rhel; then \
        sudo dnf -y install $(grep -h -v '^#' packages/base.txt packages/fedora.txt) || { echo "  ✗ dnf install failed — some packages missing"; exit 1; }; \
    fi

packages-update:
    @echo "=== Update packages ==="; \
    source scripts/detect.sh; \
    if is_msys2;   then pacman -Syu --noconfirm; \
    elif is_macos;  then brew update && brew upgrade; \
    elif is_debian; then sudo apt-get update && sudo apt-get -y upgrade; \
    elif is_rhel;   then sudo dnf -y upgrade; \
    fi

# ── MSYS2 system config ──
msys2:
    @echo "=== MSYS2 config ==="; \
    source scripts/detect.sh; \
    is_msys2 || { echo "Not MSYS2, skipping."; exit 0; }; \
    grep -q '/usr/bin/zsh' /etc/passwd 2>/dev/null || { \
        mkpasswd -c 2>/dev/null | sed 's|/usr/bin/bash|/usr/bin/zsh|' > /etc/passwd 2>/dev/null || \
        echo "$(whoami):*:$(id -u):$(id -g):$(id -un):/home/$(whoami):/usr/bin/zsh" > /etc/passwd; \
        echo "  ✓ passwd → zsh"; }; \
    grep -q 'LOGINSHELL=zsh' /msys2_shell.cmd 2>/dev/null || { \
        sed -i 's|set "LOGINSHELL=bash"|set "LOGINSHELL=zsh"|' /msys2_shell.cmd 2>/dev/null; \
        echo "  ✓ msys2_shell.cmd"; }; \
    mkdir -p ~/.local/bin; \
    for s in home/dot_local/bin/*; do \
        [ -f "$s" ] || continue; \
        [ -L ~/.local/bin/$(basename "$s") ] && continue; \
        ln -sf "$(pwd)/$s" ~/.local/bin/ 2>/dev/null && echo "  ✓ $(basename "$s")"; \
    done

# ── Dotfiles ──
dotfiles:
    @echo "=== Dotfiles ==="; \
    source scripts/detect.sh; ensure_user_bin; \
    SRC="$(cygpath -m "$(pwd)" 2>/dev/null || echo "$(pwd)")"; \
    CONF="${XDG_CONFIG_HOME:-$(cygpath -m "$HOME/.config" 2>/dev/null || echo "$HOME/.config")}"; \
    mkdir -p "$CONF/chezmoi"; \
    printf 'sourceDir = "%s/home"\n[data]\n  isWSL = false\n[interpreters.sh]\n  command = "bash"\n[interpreters.bash]\n  command = "bash"\n' "$SRC" > "$CONF/chezmoi/chezmoi.toml"; \
    chezmoi apply --interactive=false

dotfiles-update:
    @echo "=== Update dotfiles ==="; \
    source scripts/detect.sh; ensure_user_bin; \
    git pull --ff-only || echo "  (git pull failed — see error above; likely uncommitted changes or network)"; \
    chezmoi apply --interactive=false

# ── Nerd Fonts (download + install) ──
fonts:
    @echo "=== Nerd Fonts ==="; \
    source scripts/detect.sh; \
    if is_wsl; then echo "WSL uses host fonts, skipping."; exit 0; fi; \
    FONTS="$(grep -v '^#' packages/fonts.txt 2>/dev/null | grep -v '^$' || true)"; \
    [ -n "$FONTS" ] || { echo "No fonts in packages/fonts.txt"; exit 0; }; \
    B="{{ gh_proxy }}https://github.com/ryanoasis/nerd-fonts/releases/latest/download"; \
    echo "  source: {{ gh_proxy }}github.com/ryanoasis/nerd-fonts"; \
    V=""; \
    for u in "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" "{{ gh_proxy }}https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"; do \
        V=$(curl -s --connect-timeout 8 --max-time 15 "$u" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1); \
        [ -n "$V" ] && break; \
    done; \
    [ -n "$V" ] && echo "  latest: $V"; \
    if is_msys2; then MARKER="$USERPROFILE/fonts/NerdFonts/.version"; else MARKER="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/NerdFonts/.version"; fi; \
    if is_msys2; then \
        D="$USERPROFILE/fonts/NerdFonts"; mkdir -p "$D"; \
        for f in $FONTS; do \
            if [ "${FONTS_FORCE:-}" != "1" ] && [ -n "$(find "$D/$f" -type f \( -name '*.ttf' -o -name '*.otf' \) 2>/dev/null | head -n 1)" ]; then echo "  ✓ $f (installed)"; continue; fi; \
            echo "  → $f ..."; \
            T=$(mktemp -d); \
            curl -C - -fL --http1.1 --connect-timeout 30 --speed-limit 1024 --speed-time 60 --retry 3 "$B/$f.zip" -o "$T/$f.zip" || { echo "  ✗ download"; rm -rf "$T"; continue; }; \
            rm -rf "$D/$f" 2>/dev/null; mkdir -p "$D/$f"; unzip -qo "$T/$f.zip" -d "$D/$f" 2>/dev/null || { echo "  ✗ unzip"; rm -rf "$T"; continue; }; \
            rm -rf "$T"; \
        done; \
        count=$(ls -d "$D"/*/ 2>/dev/null | wc -l); \
        echo "  $count families in $D"; \
        powershell -ExecutionPolicy Bypass -File "$(pwd)/scripts/install-fonts.ps1"; \
    else \
        T=$(mktemp -d); \
        for f in $FONTS; do \
            echo "  → $f ..."; \
            if is_macos; then [ "${FONTS_FORCE:-}" != "1" ] && ls /Library/Fonts/$f-Regular.ttf >/dev/null 2>&1 && { echo "✓"; continue; }; \
            elif is_linux; then [ "${FONTS_FORCE:-}" != "1" ] && [ -n "$(find "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/NerdFonts/$f" -type f -name '*.ttf' 2>/dev/null | head -n 1)" ] && { echo "✓"; continue; }; \
            fi; \
            curl -C - -fL --http1.1 --connect-timeout 30 --speed-limit 1024 --speed-time 60 --retry 3 "$B/$f.zip" -o "$T/$f.zip" || { echo "download ✗"; continue; }; \
            unzip -qo "$T/$f.zip" -d "$T/$f" 2>/dev/null || { echo "unzip ✗"; continue; }; \
            added=0; skipped=0; \
            for ttf in "$T"/$f/*.ttf "$T"/$f/*/*.ttf; do \
                [ -f "$ttf" ] || continue; \
                fn=$(basename "$ttf"); \
                if is_macos; then \
                    [ -f "/Library/Fonts/$fn" ] && { skipped=$((skipped+1)); continue; }; \
                    cp "$ttf" /Library/Fonts/ 2>/dev/null && added=$((added+1)); \
                else \
                    D="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/NerdFonts/$f"; \
                    [ -f "$D/$fn" ] && { skipped=$((skipped+1)); continue; }; \
                    mkdir -p "$D"; cp "$ttf" "$D/" 2>/dev/null && added=$((added+1)); \
                fi; \
            done; \
            echo "+$added$( [ $skipped -gt 0 ] && echo " (${skipped} skipped)" )"; \
        done; \
        rm -rf "$T"; \
        is_linux && fc-cache -fv 2>/dev/null || true; \
    fi; \
    [ -n "$V" ] && { mkdir -p "$(dirname "$MARKER")"; printf '%s\n' "$V" > "$MARKER"; }; \
    echo "  ✓ fonts"

# ── Fonts update (version-aware) ──
fonts-update:
    @echo "=== Fonts update ==="; \
    source scripts/detect.sh; \
    if is_wsl; then echo "WSL uses host fonts, skipping."; exit 0; fi; \
    if is_msys2; then MARKER="$USERPROFILE/fonts/NerdFonts/.version"; else MARKER="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/NerdFonts/.version"; fi; \
    LATEST=""; \
    for u in "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" "{{ gh_proxy }}https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"; do \
        LATEST=$(curl -s --connect-timeout 8 --max-time 15 "$u" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1); \
        [ -n "$LATEST" ] && break; \
    done; \
    INSTALLED="$(cat "$MARKER" 2>/dev/null || true)"; \
    FORCE=""; \
    if [ -n "$LATEST" ] && [ -n "$INSTALLED" ] && [ "$LATEST" != "$INSTALLED" ]; then \
        echo "  upgrade: $INSTALLED → $LATEST"; FORCE=1; \
    elif [ -z "$LATEST" ]; then \
        echo "  (version check failed — installing missing only)"; \
    else \
        echo "  ✓ up to date ($LATEST)"; \
    fi; \
    FONTS_FORCE="$FORCE" just fonts

# ── Clean（清理遗留包 + 字体/vim/tmux/nvim 孤儿） ──
clean:
    @echo "=== Clean ==="; \
    source scripts/detect.sh; \
    if is_msys2; then \
        echo "Removing legacy packages..."; \
        for pkg in powerline-go the_silver_searcher perl-ack pylint exuberant-ctags; do \
            pacman -Q "$pkg" >/dev/null 2>&1 && { pacman -R --noconfirm "$pkg" 2>/dev/null; echo "  ✓ removed $pkg"; }; \
        done; \
        echo "Removing MSYS python + powerline-status (legacy)..."; \
        command -v pip >/dev/null 2>&1 && pip uninstall -y powerline-status 2>/dev/null || true; \
        for pkg in python python-pip python-setuptools; do \
            pacman -Q "$pkg" >/dev/null 2>&1 && { pacman -Rns --noconfirm "$pkg" 2>/dev/null && echo "  ✓ removed $pkg"; }; \
        done; \
        echo "Cleaning stale dotfiles..."; \
        rm -f ~/.dircolors ~/.fonts_installed 2>/dev/null; \
        echo "Cleaning orphan fonts..."; \
        powershell -ExecutionPolicy Bypass -Command '$keep=@(Get-Content packages/fonts.txt | Where-Object {$_ -notmatch "^#" -and $_.Trim() -ne ""} | ForEach-Object {$_.Trim()}); $store=Join-Path $env:USERPROFILE "fonts\NerdFonts"; $willInstall=@{}; foreach($f in $keep){$fd=Join-Path $store $f; if(Test-Path $fd){Get-ChildItem $fd -Filter *.ttf -ea 0 | ForEach-Object {$willInstall[$_.Name]=$true}; Get-ChildItem $fd -Filter *.otf -ea 0 | ForEach-Object {$willInstall[$_.Name]=$true}}}; $d=Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"; Get-ChildItem $d -Filter "*NerdFont*" -ea 0 | Where-Object {-not $willInstall.ContainsKey($_.Name)} | ForEach-Object {Remove-Item $_.FullName -Force; Write-Host "  del file: $($_.Name)"}; $reg="HKCU:\Software\Microsoft Windows NT\CurrentVersion\Fonts"; $item=Get-Item $reg -ea 0; if($item){foreach($pn in $item.Property){$val=$item.GetValue($pn); if($val -like "*NerdFont*"){$fn=Split-Path $val -Leaf; if(-not $willInstall.ContainsKey($fn)){Remove-ItemProperty $reg -Name $pn -Force -ea 0; Write-Host "  del reg: $pn"}}}}; Write-Host "  ✓ orphan fonts + registry"'; \
        echo "  ✓ cleaned"; \
        echo "Removing old chezmoi state..."; \
        rm -rf "${USERPROFILE}/.config/chezmoi" 2>/dev/null; \
    elif is_macos; then \
        echo "Removing legacy packages..."; \
        brew uninstall the_silver_searcher powerline-go 2>/dev/null || true; \
        rm -f ~/.dircolors; \
    elif is_linux || is_wsl; then \
        echo "Removing legacy packages..."; \
        is_debian && { sudo apt-get -y remove exuberant-ctags silversearcher-ag powerline-go vim-scripts vim-addon-manager vim-airline vim-airline-themes python3-autopep8 2>/dev/null || true; }; \
        is_rhel && { sudo dnf -y remove ctags the_silver_searcher 2>/dev/null || true; }; \
        rm -f ~/.dircolors; \
    fi; \
    rm -rf fonts LS_COLORS dotfiles snippets 2>/dev/null; \
    for d in ~/.vim/plugged/*/; do \
        [ -d "$d" ] || continue; \
        dn=$(basename "$d"); keep=0; \
        for p in $(grep -oE "^Plug '[^']+'" "$(pwd)/home/dot_vim/plugrc.vim" | cut -d/ -f2 | cut -d"'" -f1); do \
            [ "$dn" = "$p" ] && { keep=1; break; }; \
        done; \
        [ "$keep" -eq 0 ] && rm -rf "$d" && echo "  del: $dn/"; \
    done; \
    rm -rf ~/.vim/bundle 2>/dev/null; \
    rm -f ~/.vim/plugin/ctrlp.vim ~/.vim/plugin/lastplace.vim ~/.vim/plugin/youcompleteme.vim 2>/dev/null; \
    FDIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/NerdFonts"; \
    if [ -d "$FDIR" ]; then \
        rm -f "$FDIR"/*.ttf "$FDIR"/*.otf 2>/dev/null; \
        if [ -f packages/fonts.txt ]; then \
            for d in "$FDIR"/*/; do \
                [ -d "$d" ] || continue; \
                dn=$(basename "$d"); keep=0; \
                for f in $(grep -v '^#' packages/fonts.txt | grep -v '^$'); do \
                    [ "$dn" = "$f" ] && { keep=1; break; }; \
                done; \
                [ "$keep" -eq 0 ] && rm -rf "$d" && echo "  del: $dn/"; \
            done; \
        fi; \
        fc-cache -fv "$FDIR" 2>/dev/null || true; \
    fi; \
    rm -f ~/.config/chezmoi/chezmoi.yaml ~/.config/chezmoi/chezmoi.json 2>/dev/null; \
    rm -f ~/README.md ~/install.sh ~/justfile 2>/dev/null; \
    rm -rf ~/packages ~/scripts ~/bin ~/vim ~/.config/chezmoi/chezmoistate.boltdb 2>/dev/null; \
    [ -x ~/.tmux/plugins/tpm/bin/clean_plugins ] && ~/.tmux/plugins/tpm/bin/clean_plugins || true; \
    command -v nvim >/dev/null 2>&1 && nvim --headless "+Lazy! clean" +qa 2>&1 || true; \
    echo "=== Clean complete ==="
plugins:
    @echo "=== Plugins ==="; \
    if [ -n "{{ gh_proxy }}" ]; then \
        export GIT_CONFIG_COUNT=1; \
        export GIT_CONFIG_KEY_0="url.{{ gh_proxy }}https://github.com/.insteadOf"; \
        export GIT_CONFIG_VALUE_0="https://github.com/"; \
    fi; \
    if [ -f ~/.vim/autoload/plug.vim ]; then echo "  ✓ vim-plug"; \
    else curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && echo "  ✓ vim-plug"; fi; \
    mkdir -p ~/.vim; cp -f "$(pwd)/home/dot_vim/plugrc.vim" ~/.vim/pluginrc.vim 2>/dev/null && echo "  ✓ pluginrc" || echo "  ✗ pluginrc"; \
    command -v vim >/dev/null 2>&1 && { [ -f ~/.vim/plugged ] && rm ~/.vim/plugged; mkdir -p ~/.vim/plugged; echo "  installing vim plugins (git)..."; vim -e -i NONE -c 'set nomore | PlugInstall | quitall' 2>&1; missing=""; for p in $(grep -oE "^Plug '[^']+'" "$(pwd)/home/dot_vim/plugrc.vim" | cut -d/ -f2 | cut -d"'" -f1); do [ -d "$HOME/.vim/plugged/$p" ] || missing="$missing $p"; done; if [ -n "$missing" ]; then echo "  ✗ vim plugins missing:$missing"; else echo "  ✓ vim plugins"; fi; }; \
    if [ -d ~/.tmux/plugins/tpm ]; then echo "  ✓ tpm"; \
    else git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && echo "  ✓ tpm" || echo "  ✗ tpm"; fi; \
    if [ -d ~/.tmux/plugins-manual/catppuccin ]; then echo "  ✓ catppuccin"; \
    else git clone --depth 1 https://github.com/catppuccin/tmux ~/.tmux/plugins-manual/catppuccin && echo "  ✓ catppuccin" || echo "  ✗ catppuccin"; fi; \
    if [ -f ~/.tmux.conf ] && [ -x ~/.tmux/plugins/tpm/bin/install_plugins ]; then \
        echo "  installing tmux plugins (tpm)..."; \
        ~/.tmux/plugins/tpm/bin/install_plugins && echo "  ✓ tmux plugins" || echo "  ✗ tmux plugins"; \
    fi; \
    command -v nvim >/dev/null 2>&1 && { echo "  installing nvim plugins (git)..."; nvim --headless "+Lazy! sync" +qa 2>&1; echo "  ✓ nvim plugins"; };

plugins-update:
    @echo "=== Update plugins ==="; \
    if [ -n "{{ gh_proxy }}" ]; then \
        export GIT_CONFIG_COUNT=1; \
        export GIT_CONFIG_KEY_0="url.{{ gh_proxy }}https://github.com/.insteadOf"; \
        export GIT_CONFIG_VALUE_0="https://github.com/"; \
    fi; \
    command -v vim >/dev/null 2>&1 && vim -e -i NONE +PlugUpdate +qall! 2>&1 || true; \
    command -v nvim >/dev/null 2>&1 && nvim --headless "+Lazy! sync" +qa 2>&1 || true; \
    [ -d ~/.tmux/plugins/tpm ] && (cd ~/.tmux/plugins/tpm && git pull) || true
    [ -d ~/.tmux/plugins-manual/catppuccin ] && (cd ~/.tmux/plugins-manual/catppuccin && git pull) || true
    [ -x ~/.tmux/plugins/tpm/bin/update_plugins ] && ~/.tmux/plugins/tpm/bin/update_plugins || true

# ── Claude Code ──
claude-code:
    @echo "=== Claude Code ==="; \
    if command -v claude >/dev/null 2>&1; then \
        echo "  ✓ claude (up to date)"; \
    else \
        ok=0; \
        if curl -fsSL --connect-timeout 30 https://claude.ai/install.sh -o /tmp/claude-install.sh 2>/dev/null; then \
            bash /tmp/claude-install.sh && ok=1; \
            rm -f /tmp/claude-install.sh; \
        fi; \
        if [ "$ok" -ne 1 ] && command -v npm >/dev/null 2>&1; then \
            echo "  → claude.ai unreachable, trying npm (npmmirror)..."; \
            mkdir -p "$HOME/.local" && npm install -g @anthropic-ai/claude-code --prefix "$HOME/.local" --registry=https://registry.npmmirror.com && ok=1; \
        fi; \
        [ "$ok" -eq 1 ] && echo "  ✓ claude-code installed" || echo "  ✗ claude-code install failed (claude.ai blocked, npm unavailable)"; \
    fi

claude-code-update:
    @echo "=== Claude Code update ==="; \
    claude update 2>/dev/null && echo "  ✓ claude-code updated" || echo "  ✓ claude-code up to date"

# ── gitmux（tmux git 分支状态，自动取最新 release） ──
gitmux:
    @echo "=== gitmux ==="; \
    if command -v gitmux >/dev/null 2>&1; then echo "  ✓ gitmux"; \
    else \
        mkdir -p ~/.local/bin; \
        ver="$(curl -fsSL https://api.github.com/repos/arl/gitmux/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"; \
        curl -fL --progress-bar "https://github.com/arl/gitmux/releases/download/$ver/gitmux_${ver}_linux_amd64.tar.gz" -o /tmp/gitmux.tar.gz && \
        tar xzf /tmp/gitmux.tar.gz -C ~/.local/bin gitmux && rm -f /tmp/gitmux.tar.gz && echo "  ✓ gitmux $ver" || echo "  ✗ gitmux"; \
    fi

gitmux-update:
    @echo "=== gitmux update ==="; \
    ver="$(curl -fsSL https://api.github.com/repos/arl/gitmux/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"; \
    curl -fL --progress-bar "https://github.com/arl/gitmux/releases/download/$ver/gitmux_${ver}_linux_amd64.tar.gz" -o /tmp/gitmux.tar.gz && \
    tar xzf /tmp/gitmux.tar.gz -C ~/.local/bin gitmux && rm -f /tmp/gitmux.tar.gz && echo "  ✓ gitmux $ver" || echo "  ✗ gitmux update failed"

# ── Windows Terminal profile ──
wt-config: packages
    @echo "=== Windows Terminal profile ==="; \
    source scripts/detect.sh; \
    is_msys2 || { echo "Windows only."; exit 0; }; \
    command -v python >/dev/null 2>&1 || { echo "Python required. Run 'just packages' first."; exit 1; }; \
    python scripts/wt-add-profile.py
