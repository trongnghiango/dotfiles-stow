{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    
    enableGlobalCompInit = false;
    promptInit = "";
  };

  # -------------------------------------------------------------
  # Cấu hình biến môi trường qua /etc/zshenv (System Level)
  # -------------------------------------------------------------
  environment.etc."zshenv".text = ''
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_DATA_HOME="$HOME/.local/share"

    # Trỏ config Zsh
    if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
      export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
    fi

    # Thêm đường dẫn Scripts vào PATH
    # (Đảm bảo scripts trong dotfiles chạy được mà không cần symlink)
    #export PATH="$HOME/.dotfiles/bin/.local/bin:$HOME/.local/bin:$PATH"
    export PATH="$HOME/.dotfiles/bin/.local/bin:$HOME/.dotfiles/user-bin/.local/bin:$HOME/.local/bin:$PATH"

    # Load profile cũ nếu có
    if [[ -f "$XDG_CONFIG_HOME/shell/profile" ]]; then
      source "$XDG_CONFIG_HOME/shell/profile"
    fi
  '';

  environment.systemPackages = with pkgs; [
    fzf
    eza
    bat
    zoxide
    fnm
  ];

  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;
}

