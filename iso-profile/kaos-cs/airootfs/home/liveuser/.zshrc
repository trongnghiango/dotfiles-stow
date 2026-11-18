# KaOS-CS Live User .zshrc
# Minimal config for live ISO

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Colors
autoload -Uz colors && colors

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Prompt
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

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

# Key bindings
bindkey -e
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Welcome
echo "Welcome to KaOS-CS Live ISO!"
echo "Run 'install-kaos' to start installation"
echo "Run 'ka-setup all' after installation and reboot"