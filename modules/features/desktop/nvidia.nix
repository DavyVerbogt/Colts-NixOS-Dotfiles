{ self, inputs, ... }: {
  flake.nixosModules.nvidia = { config, pkgs, ... }: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true; # not strictly needed for Java MC, but good to have
    };
    hardware.nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # These three are what you're missing:
    boot.blacklistedKernelModules = [ "nouveau" ];
    boot.initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
    boot.kernelParams = [ "nvidia-drm.modeset=1" ];

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
