# ==============================================================================
# ~/.bashrc — Server-minimal (interactive Bash)
# Được source bởi ~/.bash_profile (login) hoặc bash -i.
# ==============================================================================

# Chỉ chạy cho interactive shell
case $- in
  *i*) ;;
  *) return 0 ;;
esac

# --- Fallback env nếu chưa có profile (non-login interactive) ---
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${EDITOR:=nvim}"
: "${VISUAL:=$EDITOR}"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME EDITOR VISUAL

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# --- Aliases ---
[ -f "$XDG_CONFIG_HOME/shell/aliasrc" ] && . "$XDG_CONFIG_HOME/shell/aliasrc"

# --- History ---
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE='ls:ll:la:cd:pwd:exit:clear:history'
shopt -s histappend checkwinsize
case "$PROMPT_COMMAND" in
  *"history -a"*) ;;
  *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# --- Vi mode ---
set -o vi

# --- Starship prompt (cache tĩnh) ---
if command -v starship >/dev/null 2>&1; then
  _st_cache="${XDG_CACHE_HOME}/bash/starship_init.bash"
  mkdir -p "$(dirname "$_st_cache")"
  if [ ! -f "$_st_cache" ] || [ "$(command -v starship)" -nt "$_st_cache" ]; then
    starship init bash > "$_st_cache" 2>/dev/null
  fi
  [ -f "$_st_cache" ] && . "$_st_cache"
  unset _st_cache
fi

# --- zoxide (cache tĩnh) ---
if command -v zoxide >/dev/null 2>&1; then
  _z_cache="${XDG_CACHE_HOME}/bash/zoxide_init.bash"
  mkdir -p "$(dirname "$_z_cache")"
  if [ ! -f "$_z_cache" ] || [ "$(command -v zoxide)" -nt "$_z_cache" ]; then
    zoxide init bash > "$_z_cache" 2>/dev/null
  fi
  [ -f "$_z_cache" ] && . "$_z_cache"
  unset _z_cache
fi

# --- direnv (cache tĩnh) ---
if command -v direnv >/dev/null 2>&1; then
  _d_cache="${XDG_CACHE_HOME}/bash/direnv_init.bash"
  mkdir -p "$(dirname "$_d_cache")"
  if [ ! -f "$_d_cache" ] || [ "$(command -v direnv)" -nt "$_d_cache" ]; then
    direnv hook bash > "$_d_cache" 2>/dev/null
  fi
  [ -f "$_d_cache" ] && . "$_d_cache"
  unset _d_cache
fi

# --- fzf key-bindings (Ctrl+R / Ctrl+T) ---
for _f in \
  /usr/share/doc/fzf/examples/key-bindings.bash \
  /usr/share/fzf/key-bindings.bash \
  /usr/share/fzf/shell/key-bindings.bash; do
  if [ -f "$_f" ]; then
    . "$_f"
    break
  fi
done
unset _f

# --- bash-completion ---
[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
