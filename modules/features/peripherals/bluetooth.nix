{ ... }: {
  # Noctalia's noctalia.json already has a live Bluetooth widget wired into
  # the control-center shortcuts — this is what makes it actually work
  # instead of sitting there inert.
  flake.nixosModules.bluetooth = { pkgs, ... }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;
  };
}
