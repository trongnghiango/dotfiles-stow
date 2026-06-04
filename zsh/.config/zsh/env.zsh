# Environment variables and path configurations for zsh

# History in cache directory:
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history"

# History size
HISTSIZE=10000000
SAVEHIST=10000000

# NVM
export NVM_DIR="$HOME/.config/nvm"

# FZF default options
export FZF_DEFAULT_OPTS="
--height=40%
--border
--reverse
--info=inline
"

# PNPM
export PNPM_HOME="/home/ka/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Go
if [ -d "/usr/local/go" ]; then
  export GOROOT=/usr/local/go
  export PATH=$PATH:$GOROOT/bin
fi
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Bun completions
[ -s "/home/ka/.bun/_bun" ] && source "/home/ka/.bun/_bun" 2>/dev/null

# Direnv
eval "$(direnv hook zsh)"
