{ config, pkgs, ... }:

{
  time.timeZone = "Asia/Ho_Chi_Minh";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- MỚI: nix-ld (Cứu cánh cho các binary tải ngoài Nix) ---
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    curl
  ];

  # Fonts (Giữ nguyên của bạn)
  fonts.packages = with pkgs; [
    nerd-fonts.blex-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    inter
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome
  ];

  # SSH (Giữ nguyên của bạn)
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  # Gói hệ thống cốt lõi (Giữ nguyên build tools cho DWM/ST)
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    gnumake
    gcc
    pkg-config
    xorg.libX11
    xorg.libX11.dev
    xorg.libXinerama
    xorg.libXinerama.dev
    xorg.libXft
    xorg.libXft.dev
    xorg.xrandr
    xorg.xsetroot
    unzip
    unrar
    dash
    tree
    tmux
    android-tools
  ];
}

