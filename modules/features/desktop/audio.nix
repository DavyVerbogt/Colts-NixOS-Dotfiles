{ ... }: {
  flake.nixosModules.audio = { ... }: {
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };

    # realtime scheduling for pipewire
    security.rtkit.enable = true;
  };
}
