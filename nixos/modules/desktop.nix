{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    xkb.layout = "us";

    # Tắt Login Manager, dùng startx (Arch Style)
    displayManager.startx.enable = true;

    # Khai báo DWM để NixOS tự kéo dependencies X11 về
    # Ta vẫn dùng binary tự biên dịch trong ~/.local/bin
    windowManager.dwm.enable = true;
  };

  # --- Tối ưu Intel HD4000 (Ivy Bridge) ---
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver   # iHD Driver
      vaapiIntel           # i965 Driver (Bắt buộc cho chip đời cũ này)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  services.gvfs.enable = true;   # Mount USB/Phone
  services.udisks2.enable = true; # Auto-mount backend
  services.libinput.enable = true; # Touchpad support
  
  # Hỗ trợ Android Dev/Mount
  services.udev.packages = [ pkgs.android-udev-rules ];
}
