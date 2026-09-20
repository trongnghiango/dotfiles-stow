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

# Go workspace bin for go install binaries
export GOPATH="${GOPATH:-$HOME/go}"
[ -d "$GOPATH/bin" ] && export PATH="$PATH:$GOPATH/bin"

_zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$_zsh_cache_dir"

# Direnv — per-directory environment (static cache)
if command -v direnv &>/dev/null; then
  _direnv_cache="$_zsh_cache_dir/direnv_hook.zsh"
  if [[ ! -f "$_direnv_cache" || "$(command -v direnv)" -nt "$_direnv_cache" ]]; then
    direnv hook zsh > "$_direnv_cache" 2>/dev/null
  fi
  source "$_direnv_cache"
fi

# Mise — polyglot dev runtime manager (static cache)
if command -v mise &>/dev/null; then
  _mise_cache="$_zsh_cache_dir/mise_activate.zsh"
  if [[ ! -f "$_mise_cache" || "$(command -v mise)" -nt "$_mise_cache" ]]; then
    mise activate zsh > "$_mise_cache" 2>/dev/null
  fi
  source "$_mise_cache"
fi
