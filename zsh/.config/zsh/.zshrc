# Luke's config for the Zoomer Shell
typeset -U path PATH

# Enable colors and change prompt:
autoload -U colors && colors	# Load colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.
setopt interactive_comments
unsetopt PROMPT_SP

# Load environment modules (includes PATH, history sizes, and variables)
[ -f "$ZDOTDIR/env.zsh" ] && source "$ZDOTDIR/env.zsh"

# Ensure directory exists
mkdir -p "${HISTFILE:h}"

# History behavior
setopt APPEND_HISTORY         # Append to history, không overwrite
setopt INC_APPEND_HISTORY     # Ghi ngay khi enter, không đợi đến khi thoát
setopt SHARE_HISTORY          # Share history giữa tất cả terminal sessions
setopt HIST_IGNORE_DUPS       # Không lưu entry trùng liên tiếp
setopt HIST_IGNORE_ALL_DUPS   # Xóa entry cũ nếu entry mới trùng
setopt HIST_IGNORE_SPACE      # Không lưu lệnh bắt đầu bằng dấu cách
setopt HIST_SAVE_NO_DUPS      # Không ghi entry trùng vào history file
setopt HIST_FIND_NO_DUPS      # Không hiển thị entry trùng khi search
setopt HIST_REDUCE_BLANKS     # Bỏ khoảng trắng thừa

# Load aliases and shortcuts if existent.
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"

# OS-specific aliases (arch / void / nixos)
if [ -f /etc/os-release ]; then
  OS=$(. /etc/os-release && echo "$ID")
  OS_ALIASRC="${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc.$OS"
  [ -f "$OS_ALIASRC" ] && source "$OS_ALIASRC"
fi

[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc"

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit -u
_comp_options+=(globdots)		# Include hidden files.

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# History navigation: Up/Down arrows + Vim j/k (beginning-search — prefix-aware)
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search     # Up arrow
bindkey '^[[B' down-line-or-beginning-search   # Down arrow
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search
bindkey '^r' history-incremental-search-backward  # Ctrl+R

# Load functions module
[ -f "$ZDOTDIR/functions.zsh" ] && source "$ZDOTDIR/functions.zsh"

echo -ne '\e[5 q' # Use beam shape cursor on startup.

bindkey -s '^o' '^ulfcd\n'
bindkey -s '^a' '^ubc -lq\n'
bindkey -s '^f' '^ucd "$(dirname "$(fzf)")"\n'
bindkey '^[[P' delete-char

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -M vicmd '^[[P' vi-delete-char
bindkey -M vicmd '^e' edit-command-line
bindkey -M visual '^[[P' vi-delete

# Load syntax highlighting; should be last.
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh 2>/dev/null

# Load shared profile configuration if it exists.
# Zsh's typeset -U at the top guarantees PATH remains clean and duplicate-free.
[ -f "$HOME/.config/shell/profile" ] && source "$HOME/.config/shell/profile"

# --- Zoxide: smart cd với frecency (thay thế cd thông thường) ---
# Cài: sudo pacman -S zoxide
# Dùng: cd <partial-name>  hoặc  z <partial-name>
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# --- Starship: cross-shell prompt (git-aware, fast) ---
# Cài: sudo pacman -S starship
# Fallback về PS1 ở trên nếu starship chưa cài
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# opencode
# PATH centralized in profile
