# ==============================================================================
# ~/.config/zsh/.zshrc — Interactive Zsh config (X11/DWM custom stack)
# ==============================================================================
# Load order (Zsh startup):
#   ~/.zshenv            → ZDOTDIR (every instance)
#   ~/.config/zsh/.zprofile → sources profile (login shells only)
#   ~/.config/zsh/.zshrc → THIS FILE (interactive shells)
# ==============================================================================

# Deduplicate PATH on startup
typeset -U path PATH

# Enable color support
autoload -U colors && colors

# Fallback prompt (used if Starship is not installed)
# Starship will override this at the bottom of this file.
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

# Shell options
setopt autocd               # cd into dir by typing its name
setopt interactive_comments # allow # comments in interactive shell
unsetopt PROMPT_SP          # don't print partial-line marker
stty stop undef             # disable ctrl-s freeze

# ==============================================================================
# ENVIRONMENT
# ==============================================================================

# Load tool-specific env (Go, Bun, FZF, direnv) — NOT profile, that's .zprofile
[ -f "$ZDOTDIR/env.zsh" ] && source "$ZDOTDIR/env.zsh"

# History file location & sizes
export HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history"
export HISTSIZE=10000000
export SAVEHIST=10000000

# Ensure history directory exists
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

# ==============================================================================
# HISTORY OPTIONS
# ==============================================================================

setopt APPEND_HISTORY         # Append to history file, don't overwrite
setopt INC_APPEND_HISTORY     # Write immediately, not on exit
setopt SHARE_HISTORY          # Share history across all sessions
setopt HIST_IGNORE_DUPS       # Don't record duplicate consecutive entries
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate
setopt HIST_IGNORE_SPACE      # Do not record an event starting with a space
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries in the history file
setopt HIST_FIND_NO_DUPS      # Do not display a line previously found
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks

# ==============================================================================
# ALIASES & SHORTCUTS
# ==============================================================================

[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ]       && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"

# ==============================================================================
# COMPLETION (Optimized with caching)
# ==============================================================================

autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist

# Cache completion dump: only re-compile once every 24 hours
_comp_dump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "${_comp_dump:h}"
if [[ -s "$_comp_dump" && (! -n "$_comp_dump"(#qN.md-1)) ]]; then
  compinit -C -d "$_comp_dump"
else
  compinit -u -d "$_comp_dump"
fi
_comp_options+=(globdots)   # Include hidden files in completion

# ==============================================================================
# VI MODE
# ==============================================================================

bindkey -v
export KEYTIMEOUT=1         # Faster mode switch (10ms)

# Vim keys in tab completion menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# History navigation in Vi Mode & Insert Mode (Up/Down arrows + Vim j/k + Ctrl+R)
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search     # Up Arrow
bindkey '^[[B' down-line-or-beginning-search   # Down Arrow
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search
bindkey '^r' history-incremental-search-backward

# ==============================================================================
# FUNCTIONS & KEYBINDS
# ==============================================================================

# Load vi cursor shape + lfcd
[ -f "$ZDOTDIR/functions.zsh" ] && source "$ZDOTDIR/functions.zsh"

# Beam cursor on startup
echo -ne '\e[5 q'

# Ctrl+O → open lf file manager (cd to selected dir on exit)
bindkey -s '^o' '^ulfcd\n'
# Ctrl+A → bc calculator
bindkey -s '^a' '^ubc -lq\n'
# Ctrl+F → fzf cd to file's parent dir
bindkey -s '^f' '^ucd "$(dirname "$(fzf)")"\n'
bindkey '^[[P' delete-char

# Ctrl+E → edit current command line in $EDITOR
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -M vicmd '^[[P' vi-delete-char
bindkey -M vicmd '^e' edit-command-line
bindkey -M visual '^[[P' vi-delete

# ==============================================================================
# PLUGINS (order matters — syntax highlight before starship)
# ==============================================================================

# 1. Syntax highlighting — colorize commands as you type
#    green = valid command, red = not found, yellow = string, etc.
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]; then
  source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
elif [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# 2. Zoxide — smart directory jumper (static cache)
#    Usage: cd <partial-name>  OR  z <partial-name>
#    Install: sudo pacman -S zoxide
if command -v zoxide &>/dev/null; then
  _zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zoxide_init.zsh"
  if [[ ! -f "$_zoxide_cache" || "$(command -v zoxide)" -nt "$_zoxide_cache" ]]; then
    zoxide init zsh --cmd cd > "$_zoxide_cache" 2>/dev/null
  fi
  source "$_zoxide_cache"
fi

# 3. Starship — cross-shell prompt (static cache)
#    Must be LAST — replaces PS1 defined above (PS1 is the fallback if absent)
#    Install: sudo pacman -S starship
if command -v starship &>/dev/null; then
  _starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/starship_init.zsh"
  if [[ ! -f "$_starship_cache" || "$HOME/.config/starship.toml" -nt "$_starship_cache" || "$(command -v starship)" -nt "$_starship_cache" ]]; then
    starship init zsh --print-full-init > "$_starship_cache" 2>/dev/null
  fi
  source "$_starship_cache"
fi
