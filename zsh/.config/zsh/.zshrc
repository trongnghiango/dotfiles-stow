# ==============================================================================
# ~/.config/zsh/.zshrc — Interactive Zsh config (Omarchy + custom stack)
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

# Ensure history directory exists (HISTFILE = $XDG_DATA_HOME/zsh/history)
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

# ==============================================================================
# HISTORY
# ==============================================================================

setopt APPEND_HISTORY       # Append to history file, don't overwrite
setopt INC_APPEND_HISTORY   # Write immediately, not on exit
setopt SHARE_HISTORY        # Share history across all sessions
setopt HIST_IGNORE_DUPS     # Don't record duplicate consecutive entries
setopt HIST_REDUCE_BLANKS   # Remove superfluous blanks

# ==============================================================================
# ALIASES & SHORTCUTS
# ==============================================================================

[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc" ]    && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ]       && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc"

# ==============================================================================
# COMPLETION
# ==============================================================================

autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit -u
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
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh 2>/dev/null

# 2. Zoxide — smart directory jumper (replaces `cd` with frecency-based z)
#    Usage: cd <partial-name>  OR  z <partial-name>
#    Install: sudo pacman -S zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# 3. Starship — cross-shell prompt (shows git, lang versions, exit code...)
#    Must be LAST — replaces PS1 defined above (PS1 is the fallback if absent)
#    Install: sudo pacman -S starship
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
