{ ... }: {

  # Screenshot and screen recording feature.
  # grim/slurp/swappy cover stills; wf-recorder covers video.
  # The niri keybinds (Print, Shift+Print, Alt+Print) are defined in niri.nix
  # and call niri's native screenshot action, not grim directly.
  flake.nixosModules.screenshot = { pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      grim       # Wayland screenshot capture
      slurp      # interactive region selector (used by grim/swappy)
      swappy     # annotate and save screenshots after capture
      wf-recorder # Wayland screen recorder
    ];
  };
}
