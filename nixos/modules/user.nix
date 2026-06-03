{ config, pkgs, ... }:

{
  users.users.ka = {
    isNormalUser = true;
    description = "Ka";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "storage" ];
    shell = pkgs.zsh;
  };
}

