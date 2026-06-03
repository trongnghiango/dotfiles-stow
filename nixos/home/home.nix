{ config, pkgs, dotfiles, ... }:

{
  home.username = "ka";
  home.homeDirectory = "/home/ka";

  # --- Cài đặt Phần mềm User ---
  home.packages = with pkgs; [
    # 1. GUI Apps
    librewolf nsxiv zathura mpv dunst rofi calcurse
    pavucontrol networkmanagerapplet trayer xwallpaper arandr
    
    # 2. Âm thanh (Đã thêm vào đây)
    pulsemixer      # Giao diện Mixer Terminal
    pamixer         # Điều khiển volume CLI
    wireplumber     # Để có lệnh wpctl
    
    # 3. CLI Tools & Neovim Helpers (Sửa lỗi checkhealth)
    neovim
    lazygit
    sqlite          # Cho Snacks picker
    trash-cli       # Lệnh trash
    ghostscript     # Xem PDF
    tectonic        # Render LaTeX
    util-linux      # Lệnh setsid cho script volume

    # 4. Dev Tools & LSP (Thay thế Mason hoàn toàn)
    lua-language-server
    gopls
    zls
    nodePackages.typescript-language-server
    rust-analyzer
    pyright
    vscode-langservers-extracted # html, css, jsonls
    bash-language-server
    nil
    # Formatters/Linters
    stylua
    gotools
    nodePackages.prettier
    nodePackages.eslint_d
    shellcheck
    shfmt
    ruff
    # Runtimes
    nodejs_22
    python3
    go
    zig

    # 5. CLI Essentials (Giữ nguyên của bạn)
    fzf ripgrep fd eza bat htop btop ncmpcpp mpc
    newsboat neomutt lf ueberzugpp ffmpeg ffmpegthumbnailer
    imagemagick poppler-utils atool xclip maim slop
    brightnessctl libnotify jq socat bc mediainfo
  ];

  # --- SYMLINK CONFIGURATION (Giữ nguyên logic của bạn) ---
  home.file = {
    # Pointer cho Zsh (Triết lý Clean Home của bạn)
    ".zshenv".text = ''
      export ZDOTDIR="$HOME/.config/zsh"
    '';

    # Symlinks trỏ về dotfiles
    ".config/zsh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/zsh/.config/zsh";
    ".config/shell".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/shell/.config/shell";
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

    # X11 & Scripts
    ".xinitrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/x11/.config/x11/xinitrc";
    ".xprofile".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/x11/.config/x11/xprofile";
    ".config/x11".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/x11/.config/x11";

    ".local/bin/base".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/.local/bin";
    ".local/bin/user".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/user-bin/.local/bin/user";
  };

  # CẬP NHẬT PATH
  home.sessionPath = [
    "$HOME/.local/bin"        # Nơi chứa dwm, st (build tay)
    "$HOME/.local/bin/base"   # Nơi chứa các script cơ bản
    "$HOME/.local/bin/user"   # Nơi chứa các script ka-*
  ];

  # Theme GTK
  gtk = {
    enable = true;
    theme = { name = "Arc-Dark"; package = pkgs.arc-theme; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    cursorTheme = { name = "Adwaita"; package = pkgs.adwaita-icon-theme; };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "st";
    BROWSER = "librewolf";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  home.stateVersion = "24.11";
}

