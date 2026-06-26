{ ... }: {

  # Media and hardware controls feature.
  # playerctl handles media keys (the niri binds call it via getExe in the
  # wrapped package, but it's also useful standalone).
  # pavucontrol is the GUI mixer for PipeWire/Pulse.
  # brightnessctl controls backlight brightness.
  flake.nixosModules.media = { pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      playerctl    # media key control (play/pause/next/prev)
      pavucontrol  # PipeWire/Pulse audio mixer GUI
      brightnessctl # backlight brightness control
    ];
  };
}
