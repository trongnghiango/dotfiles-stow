{ config, pkgs, ... }:

{
  # Tắt PulseAudio cũ để tránh conflict
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # Layer tương thích PulseAudio
    wireplumber.enable = true;
  };
}

