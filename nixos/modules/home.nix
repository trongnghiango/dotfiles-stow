{ config, pkgs, dotfiles, ... }:

{
  home.username = "ka";
  home.homeDirectory = "/home/ka";

  # --- Cài đặt Phần mềm User ---
  home.packages = with pkgs; [
    # GUI Apps
    librewolf
    nsxiv
    zathura
    mpv
    dunst
    rofi
    calcurse
    pavucontrol
    networkmanagerapplet
    trayer
    xwallpaper
    arandr
    
    # CLI Tools (Dependencies cho scripts của bạn)
    neovim
    fzf
    ripgrep
    fd
    eza
    bat
    htop
    btop
    ncmpcpp
    mpc-cli
    newsboat
    neomutt
    lf
    ueberzugpp      # Thay thế ueberzug cũ (Cần cho lf preview ảnh)
    ffmpeg
    ffmpegthumbnailer
    imagemagick
    poppler_utils   # pdftoppm
    atool
    xclip
    maim
    slop
    brightnessctl
    libnotify
    jq
    socat
    bc
    mediainfo
  ];

  # --- SYMLINK CONFIGURATION (Thay thế Stow) ---
  # Sử dụng 'mkOutOfStoreSymlink' để trỏ trực tiếp về ~/.dotfiles/
  # Sửa file trong dotfiles -> Có tác dụng ngay lập tức.

  home.file = {
    # 1. Shell Configs
    ".config/zsh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/zsh/.config/zsh";
    ".config/shell".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/shell/.config/shell";

    # 2. App Configs
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim/.config/nvim";
    ".config/lf".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lf/.config/lf";
    ".config/dunst".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/dunst/.config/dunst";
    ".config/newsboat".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/.local/share/newsboat"; 
    ".config/mpd".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/media/.config/mpd";
    ".config/ncmpcpp".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/media/.config/ncmpcpp";
    ".config/mpv".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/media/.config/mpv";
    ".config/nsxiv".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nsxiv/.config/nsxiv";
    ".config/librewolf".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/librewolf/.config/librewolf";
    ".config/tmux".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/tmux/.config/tmux";
    
    # 3. X11 & Scripts (Đã sửa lại để tương thích NixOS)
    ".xinitrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/x11/.config/x11/xinitrc";
    ".xprofile".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/x11/.config/x11/xprofile";
    ".config/x11".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/x11/.config/x11";
    
    # Symlink toàn bộ script vào PATH
    ".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/.local/bin";
    
    # Nếu bạn muốn gộp user-bin vào luôn:
    ".local/bin/user".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/user-bin/.local/bin/user";
  };

  # 2. CẬP NHẬT PATH (Thêm đoạn này)
  # Để terminal tìm thấy lệnh trong cả 2 thư mục con vừa tạo
  home.sessionPath = [
    "$HOME/.local/bin"        # Cho dwm, st (binary biên dịch tay)
#"$HOME/.local/bin/base"   # Cho các script cơ bản
    "$HOME/.local/bin/user"   # Cho các script ka-*
  ];

  # Theme GTK
  gtk = {
    enable = true;
    theme = {
      name = "Arc-Dark";
      package = pkgs.arc-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "st";
    BROWSER = "librewolf";
    _JAVA_AWT_WM_NONREPARENTING = "1"; # Fix lỗi Java app trên DWM
  };

  home.stateVersion = "24.11";
}
