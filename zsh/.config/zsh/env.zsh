# ~/.config/zsh/env.zsh
# Zsh-specific runtime environment — tool paths, dev SDKs, shell helpers.
# Env vars và HISTFILE được quản lý bởi ~/.config/shell/profile (login shell).
# File này chỉ chứa config zsh-specific hoặc tool cần lazy-load trong shell.

# History size (HISTFILE = $XDG_DATA_HOME/zsh/history, set bởi profile — không override ở đây)
HISTSIZE=10000000
SAVEHIST=10000000

# FZF — fuzzy finder options
export FZF_DEFAULT_OPTS="
  --height=40%
  --border
  --reverse
  --info=inline
"

# Go — chỉ cần GOPATH, GOROOT không cần set thủ công khi cài qua pacman
export GOPATH="$HOME/go"
[ -d "$GOPATH/bin" ] && export PATH="$PATH:$GOPATH/bin"

# Bun — JavaScript runtime
export BUN_INSTALL="$HOME/.bun"
if [ -d "$BUN_INSTALL/bin" ]; then
  export PATH="$BUN_INSTALL/bin:$PATH"
fi
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun" 2>/dev/null

# Direnv — per-directory environment
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# NVM — Node Version Manager (lazy load để tránh chậm shell startup)
# Uncomment khi cần sử dụng nvm. PNPM đã được config trong profile.
# export NVM_DIR="${XDG_CONFIG_HOME}/nvm"
# _nvm_lazy_load() {
#   unset -f nvm node npm npx
#   [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
#   [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
# }
# nvm() { _nvm_lazy_load; nvm "$@"; }
# node() { _nvm_lazy_load; node "$@"; }
# npm() { _nvm_lazy_load; npm "$@"; }
# npx() { _nvm_lazy_load; npx "$@"; }
