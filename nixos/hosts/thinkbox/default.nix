{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # Nhớ copy file này từ /etc/nixos/ vào
    ../../modules/core.nix
    ../../modules/shell.nix
    ../../modules/user.nix
    ../../modules/desktop.nix
    ../../modules/audio.nix
  ];

  # Bootloader: Systemd-boot (UEFI). Nếu máy cũ dùng BIOS Legacy, hãy đổi sang Grub.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thinkbox";
  networking.networkmanager.enable = true;

  system.stateVersion = "24.11"; 
}
