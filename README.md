# MyWorkEnv

Personal working environment powered by [chezmoi](https://chezmoi.io/).

Tested on MSYS2 (UCRT64/CLANG64), Ubuntu, Fedora, and macOS.

## Features

- Zsh with starship prompt
- Vim IDE with 30+ plugins (vim-plug, airline status bar)
- Tmux with TPM + powerline status bar
- Nerd Fonts (selective download)
- Cross-platform package management (pacman/apt/dnf/brew)
- Claude Code integration (MSYS2 shell auto-detection)

## Quick Start

```bash
git clone https://github.com/1bool/MyWorkEnv.git
cd MyWorkEnv
./install.sh          # installs just, then full setup
```

## Just Recipes

| Command | What |
|---------|------|
| `just` / `just --list` | List all recipes |
| `just install` | Full install (idempotent, skips existing) |
| `just update` | Upgrade packages + dotfiles + plugins + fonts |
| `just bootstrap` | Essentials only (unzip, chezmoi, git) |
| `just packages` | System packages only |
| `just dotfiles` | Deploy dotfiles via chezmoi |
| `just fonts` | Download + install Nerd Fonts |
| `just plugins` | vim-plug + tmux TPM |
| `just msys2` | MSYS2 config (zsh shell, scripts, Claude) |
| `just migrate` | Remove legacy packages from old system |
| `just wt-config` | Add profile to Windows Terminal |

Update sub-recipes: `just packages-update`, `just dotfiles-update`, `just plugins-update`

## Vim Key Bindings

| Key | Action |
|-----|--------|
| `<F6>` / `tf` | Toggle file explorer (NERDTree) |
| `<F7>` / `tt` | Toggle tag bar |
| `<F2>` | Toggle paste mode |
| `<C-p>` | Fuzzy file find (fzf) |
| `<leader>b` | Buffer list (fzf) |
| `gs` | Grep with ripgrep (Rg) |
| `<leader>*` | Search word under cursor |
| `gn` / `gp` | Next / previous buffer |
| `gx` | Close buffer |
| `gb` | Buffer explorer |
| `ge` | File explorer (netrw) |
| `K` | Man page for word under cursor |
| `<leader>b` | Toggle light/dark background |
| `<C-J/K/H/L>` | Navigate splits |
| `wK/J/H/L` | Resize splits |
| `<C-TAB>` / `<C-S-TAB>` | Next / previous buffer |
| `<C-X>` / `<S-Del>` | Cut to system clipboard |
| `<C-C>` / `<C-Insert>` | Copy to system clipboard |
| `<S-Insert>` / `<C-V>` | Paste from system clipboard |

## Tmux Key Bindings

| Key | Action |
|-----|--------|
| `Prefix r` | Reload config |
| `Prefix \|` | Split horizontal |
| `Prefix -` | Split vertical |
| `Alt-h/j/k/l` | Navigate panes |
| `Prefix h/l` | Previous / next window |
| `Prefix H/J/K/L` | Resize panes |

`Prefix` is `Ctrl-b`. Mouse enabled. Copy to system clipboard via `tmux-yank`.
