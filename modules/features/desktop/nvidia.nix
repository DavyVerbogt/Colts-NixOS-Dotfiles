{ self, inputs, ... }: {
  flake.nixosModules.nvidia = { config, pkgs, ... }: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true; # not strictly needed for Java MC, but good to have
    };

    hardware.nvidia = {
      modesetting.enable = true;
      open = false; # proprietary kernel module (better Wayland support)
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
