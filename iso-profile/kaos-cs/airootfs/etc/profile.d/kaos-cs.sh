# KaOS-CS Environment Setup
# Sourced by /etc/profile for all shells

export KAOS_CS_VERSION="1.0.0"
export KAOS_CS_PROFILE="kaos-cs"

# Ensure XDG directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Path additions
export PATH="$HOME/.local/bin:$PATH"

# Default applications
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="firefox"
export TERMINAL="st"
export PAGER="bat"

# Qt/GTK theming
export QT_QPA_PLATFORMTHEME="gtk3"
export GTK_THEME="Adwaita:dark"
export QT_STYLE_OVERRIDE="adwaita-dark"

# Fcitx5
export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
export XMODIFIERS="@im=fcitx"
export SDL_IM_MODULE="fcitx"
export GLFW_IM_MODULE="fcitx"

# Java
export _JAVA_AWT_WM_NONREPARENTING=1
export AWT_TOOLKIT="MToolkit"

# Fix for Java apps in DWM
export JAVA_HOME="/usr/lib/jvm/default"