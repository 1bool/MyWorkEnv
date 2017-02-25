# For mac not having /usr/local/{,s}bin needed by brew
PATH="/usr/local/bin:/usr/local/sbin:$PATH"
if [ -d "$HOME/Library/Python/2.7/bin" ]; then
	PATH="$HOME/Library/Python/2.7/bin:$PATH"
fi

