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

install: bootstrap packages msys2 dotfiles fonts plugins claude-code
    @echo "=== MyWorkEnv installed ==="

update: packages-update dotfiles-update plugins-update bootstrap-update claude-code-update
    @echo "=== MyWorkEnv updated ==="

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
	          | sed "s|https://github.com/|{{ gh_proxy }}https://github.com/|g; s|curl -w '%{http_code}'|curl --http1.1 --connect-timeout 30 --max-time 600 -w '%{http_code}'|g; s|-fsSL|-fL|g" \
	          | bash -s -- -b "$USERPROFILE/.local/bin"; \
	    else \
	        curl -fsSL --connect-timeout 30 --retry 3 get.chezmoi.io \
	          | sed "s|https://github.com/|{{ gh_proxy }}https://github.com/|g; s|curl -w '%{http_code}'|curl --http1.1 --connect-timeout 30 --max-time 600 -w '%{http_code}'|g; s|-fsSL|-fL|g" \
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
        pacman -S --noconfirm --needed $(grep -v '^#' packages/base.txt) $(grep -v '^#' packages/cygwin-msys.txt); \
        MINGW=""; \
        for pkg in $(grep -v '^#' packages/cygwin-mingw.txt); do \
            MINGW="$MINGW ${MINGW_PACKAGE_PREFIX}-$pkg"; \
        done; \
        [ -n "$MINGW" ] && pacman -S --noconfirm --needed -- $MINGW; \
        pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple 2>/dev/null || true; \
        pip install --user --break-system-packages powerline-status || echo "  ⚠ powerline-status install failed"; \
    elif is_macos; then \
        command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"; \
        brew install $(grep -h -v '^#' packages/base.txt packages/macos.txt); \
    elif is_debian; then \
        for src in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do \
            [ -f "$$src" ] && sudo sed -i \
                -e 's|http://[^/]*archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' \
                -e 's|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' \
                "$$src"; \
        done; \
        sudo apt-get update; \
        sudo apt-get -y install $(grep -h -v '^#' packages/base.txt packages/debian.txt); \
        pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple 2>/dev/null || true; \
        [ -f packages/pip.txt ] && for pkg in $(grep -v '^#' packages/pip.txt); do \
            command -v "$pkg" >/dev/null 2>&1 && continue; \
            pip install --user --break-system-packages "$pkg" || true; \
        done; \
    elif is_rhel; then \
        sudo dnf -y install $(grep -h -v '^#' packages/base.txt packages/fedora.txt); \
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
    if is_msys2; then \
        D="$USERPROFILE/fonts/NerdFonts"; VERFILE="$D/.version"; mkdir -p "$D"; \
        LATEST=$(curl -s "{{ gh_proxy }}https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" 2>/dev/null | grep '"tag_name"' | head -1 | cut -d'"' -f4); \
        if [ -n "$LATEST" ] && [ -f "$VERFILE" ] && [ "$(cat "$VERFILE")" = "$LATEST" ]; then \
            echo "  Fonts up to date."; \
        else \
            for f in $FONTS; do \
                echo -n "  → $f ... "; \
                T=$(mktemp -d); \
                curl -fL --http1.1 --connect-timeout 30 --max-time 600 --retry 3 "$B/$f.zip" -o "$T/$f.zip" || { echo "download ✗"; rm -rf "$T"; continue; }; \
                rm -rf "$D/$f" 2>/dev/null; unzip -qo "$T/$f.zip" -d "$D/$f" 2>/dev/null || { echo "unzip ✗"; rm -rf "$T"; continue; }; \
                rm -rf "$T"; echo "✓"; \
            done; \
            echo "$LATEST" > "$VERFILE"; \
        fi; \
        count=$(ls -d "$D"/*/ 2>/dev/null | wc -l); \
        echo "  $count families in $D"; \
        powershell -ExecutionPolicy Bypass -File "$(pwd)/scripts/install-fonts.ps1"; \
    else \
        T=$(mktemp -d); \
        for f in $FONTS; do \
            echo -n "  → $f ... "; \
            if is_macos; then ls /Library/Fonts/$f-Regular.ttf >/dev/null 2>&1 && { echo "✓"; continue; }; \
            elif is_linux; then [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/NerdFonts/$f" ] && { echo "✓"; continue; }; \
            fi; \
            curl -fL --http1.1 --connect-timeout 30 --max-time 600 --retry 3 "$B/$f.zip" -o "$T/$f.zip" || { echo "download ✗"; continue; }; \
            unzip -qo "$T/$f.zip" -d "$T/$f" 2>/dev/null || { echo "unzip ✗"; continue; }; \
            added=0; skipped=0; \
            for ttf in "$T"/$f/*.ttf; do \
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
    echo "  ✓ fonts"

# ── Fonts update (force reinstall) ──
fonts-update:
    @echo "=== Fonts update ==="; \
    source scripts/detect.sh; \
    if is_wsl; then echo "WSL uses host fonts, skipping."; exit 0; fi; \
    if is_msys2; then \
        D="$USERPROFILE/fonts/NerdFonts"; rm -f "$D/.version"; \
        just fonts; \
    else \
        just fonts; \
    fi

# ── Migrate from old system ──
migrate:
    @echo "=== Migrate from old MyWorkEnv ==="; \
    source scripts/detect.sh; \
    if is_msys2; then \
        echo "Removing legacy packages..."; \
        for pkg in powerline-go the_silver_searcher perl-ack pylint exuberant-ctags; do \
            pacman -Q "$pkg" >/dev/null 2>&1 && { pacman -R --noconfirm "$pkg" 2>/dev/null; echo "  ✓ removed $pkg"; }; \
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
    for d in syntastic ctrlp ctrlp.vim vim-grepper autopep8 YouCompleteMe; do rm -rf ~/.vim/plugged/"$d" 2>/dev/null; done; \
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
    echo "=== Migration complete ==="
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
    command -v vim >/dev/null 2>&1 && { [ -f ~/.vim/plugged ] && rm ~/.vim/plugged; mkdir -p ~/.vim/plugged; echo "  installing vim plugins (git)..."; vim -i NONE -c 'set nomore | PlugInstall | quitall' 2>&1; echo "  ✓ vim plugins"; }; \
    if [ -d ~/.tmux/plugins/tpm ]; then echo "  ✓ tpm"; \
    else git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && echo "  ✓ tpm" || echo "  ✗ tpm"; fi

plugins-update:
    @echo "=== Update plugins ==="; \
    if [ -n "{{ gh_proxy }}" ]; then \
        export GIT_CONFIG_COUNT=1; \
        export GIT_CONFIG_KEY_0="url.{{ gh_proxy }}https://github.com/.insteadOf"; \
        export GIT_CONFIG_VALUE_0="https://github.com/"; \
    fi; \
    command -v vim >/dev/null 2>&1 && vim -i NONE +PlugUpdate +qall! 2>&1 || true; \
    [ -d ~/.tmux/plugins/tpm ] && (cd ~/.tmux/plugins/tpm && git pull) || true

# ── Claude Code ──
claude-code:
    @echo "=== Claude Code ==="; \
    if command -v claude >/dev/null 2>&1; then \
        echo "  ✓ claude (up to date)"; \
    else \
        curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null && echo "  ✓ claude-code installed"; \
    fi

claude-code-update:
    @echo "=== Claude Code update ==="; \
    claude update 2>/dev/null && echo "  ✓ claude-code updated" || echo "  ✓ claude-code up to date"

# ── Windows Terminal profile ──
wt-config: packages
    @echo "=== Windows Terminal profile ==="; \
    source scripts/detect.sh; \
    is_msys2 || { echo "Windows only."; exit 0; }; \
    command -v python >/dev/null 2>&1 || { echo "Python required. Run 'just packages' first."; exit 1; }; \
    python scripts/wt-add-profile.py
