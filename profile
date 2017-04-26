# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Powerline
if which powerline-daemon &> /dev/null; then
    powerline-daemon -q
fi

if [ -r "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

if [ -r "$HOME/.path" ]; then
    . "$HOME/.path"
fi
