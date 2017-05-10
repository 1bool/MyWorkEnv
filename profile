# set PATH so it includes user's private bin if it exists
PATH=$HOME/bin:$HOME/.local/bin:$PATH

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
