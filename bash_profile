# For mac not having /usr/local/{,s}bin needed by brew
if [ "$(uname -s)" = Darwin ]; then
	PATH="/usr/local/bin:/usr/local/sbin:$PATH"
    if [ -d "$HOME/Library/Python/2.7/bin" ]; then
        PATH="$HOME/Library/Python/2.7/bin:$PATH"
    fi
fi

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

if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
fi
