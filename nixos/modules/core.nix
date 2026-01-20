{ config, pkgs, ... }:

{
  time.timeZone = "Asia/Ho_Chi_Minh";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Fonts cần thiết cho DWM/St
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    inter
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    font-awesome
  ];

  # Gói hệ thống cốt lõi (Build tools cho DWM/ST)
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    gnumake
    gcc
    pkg-config
    # Dependencies X11 để compile
    xorg.libX11
    xorg.libX11.dev
    xorg.libXinerama
    xorg.libXinerama.dev
    xorg.libXft
    xorg.libXft.dev
    xorg.xrandr
    xorg.xsetroot # Cần cho dwmblocks
    unzip
    unrar
    dash # Shell tốc độ cao cho script /bin/sh
  ];
}
