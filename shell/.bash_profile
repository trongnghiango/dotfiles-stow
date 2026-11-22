# ==============================================================================
# ~/.bash_profile — Server-minimal (login shell)
# Thứ tự: profile (env) → bashrc (interactive)
# ==============================================================================

[ -f "$HOME/.config/shell/profile" ] && . "$HOME/.config/shell/profile"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
