# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
#export PS1="\[\033[38;5;39m\][\u@\h]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;10m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]\\[$(tput sgr0)\]\[\033[36;1;11m\]\$(parse_git_branch)\[$(tput sgr0)\]\[\033[38;5;15m\]\n\[$(tput sgr0)\]\[\033[38;5;11m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"

if [ -f $HOME/.bash_functions ]; then
    . $HOME/.bash_functions
fi

if [ -f $HOME/.bash_aliases ]; then
    . $HOME/.bash_aliases
fi

. $HOME/pureline/pureline $HOME/.pureline.conf

