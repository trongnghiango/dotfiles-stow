# ~/.zshenv — Read by EVERY zsh instance (login, interactive, script).
# Chỉ đặt ZDOTDIR ở đây để zsh tìm .zprofile/.zshrc tại ~/.config/zsh/
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
