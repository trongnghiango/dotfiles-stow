{ config, pkgs, ... }:

{
  # Cài đặt Zsh và Plugin hệ thống
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # --- CLEAN HOME STRATEGY ---
    # Ép Zsh tìm config trong .config/zsh ngay từ cấp hệ thống (/etc/zshenv)
    # Không cần tạo file .zshenv hay .zshrc ở Home nữa.
    shellInit = ''
      export XDG_CONFIG_HOME="$HOME/.config"
      export XDG_CACHE_HOME="$HOME/.cache"
      export XDG_DATA_HOME="$HOME/.local/share"

      if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
        export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
      fi
      
      # Load biến môi trường từ dotfiles cũ sớm nhất có thể
      if [[ -f "$XDG_CONFIG_HOME/shell/profile" ]]; then
        source "$XDG_CONFIG_HOME/shell/profile"
      fi
    '';
    
    # Tắt config mặc định của NixOS để dùng 100% config của bạn
    enableGlobalCompInit = false;
    promptInit = ""; 
  };

  # Công cụ bổ trợ Shell
  environment.systemPackages = with pkgs; [
    fzf
    eza
    bat
    zoxide
    fnm # Thay thế nvm (quản lý nodejs)
  ];

  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;
}
