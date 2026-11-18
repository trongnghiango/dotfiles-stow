# KaOS-CS Live User .bashrc
# Minimal config for live ISO

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Colors
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Shortcuts
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'

# System
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'

# KaOS-CS
alias install-kaos='sudo /root/install.sh'
alias ka-setup='~/.dotfiles/scripts/.local/bin/ka-setup'

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Welcome message
echo "Welcome to KaOS-CS Live ISO!"
echo "Run 'install-kaos' to start installation"
echo "Run 'ka-setup all' after installation and reboot"