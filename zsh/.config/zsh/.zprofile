# ~/.config/zsh/.zprofile
# Đọc bởi zsh LOGIN shell (sau .zshenv, trước .zshrc).
# Vì ZDOTDIR được set trong ~/.zshenv, zsh sẽ tìm file này tại
# $ZDOTDIR/.zprofile = ~/.config/zsh/.zprofile — không phải ~/.zprofile.
#
# Phân công:
#   .zshenv   → ZDOTDIR only (mọi zsh instance)
#   .zprofile → source profile (chỉ login shell)
#   .zshrc    → interactive config only

[ -f "$HOME/.config/shell/profile" ] && . "$HOME/.config/shell/profile"

# Start graphical server on user's current tty if not already running.
[ "$(tty)" = "/dev/tty1" ] && ! pidof -s Xorg >/dev/null 2>&1 && exec startx "$XINITRC"

