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
export EDITOR=vim
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"

if [ -f $HOME/.bash_functions ]; then
    . $HOME/.bash_functions
fi

if [ -f $HOME/.bash_aliases ]; then
    . $HOME/.bash_aliases
fi

#export PS1='\[\e[0;38;5;39m\][\[\e[0;38;5;39m\]\u\[\e[0;38;5;39m\]@\[\e[0;38;5;39m\]\h\[\e[0;38;5;39m\]]\[\e[m\] \[\e[0;38;5;35m\]\w\[\e[m\]\[\e[0;38;5;37m\]$(parse_git_branch)\[\e[m\]\n\[\e[0;38;5;226m\]\$\[\e[m\] \[\e0'
. $HOME/pureline/pureline $HOME/.pureline.conf

