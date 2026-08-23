# ~/.zprofile
# Đọc bởi bash login shell (hoặc zsh khi ZDOTDIR chưa được set).
# Khi zsh đã có ZDOTDIR (set qua ~/.zshenv), nó đọc $ZDOTDIR/.zprofile
# thay vì file này. File này là fallback cho bash và các POSIX shell khác.
[ -f "$HOME/.config/shell/profile" ] && . "$HOME/.config/shell/profile"
