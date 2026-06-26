{ self, inputs, ... }:

{
  flake.nixosModules.steam =
    {
      pkgs,
      lib,
      ...
    }:
    {
      nixpkgs.overlays = [
        inputs.millennium.overlays.default
      ];

      programs.steam = {
        enable = true;
        package = pkgs.millennium-steam;

        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = false;
      };

      # Gamemode for performance optimization
      programs.gamemode = {
        enable = true;

        settings = {
          general = {
            renice = 10;
          };

          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
          };
        };
      };

      # Gamescope compositor
      programs.gamescope = {
        enable = false;
        capSysNice = true;
      };

      # Enable 32-bit libraries for games
      hardware.graphics.enable32Bit = true;

      # Gaming packages
      environment.systemPackages = with pkgs; [
        # Launchers
        faugus-launcher

        # Proton/Wine
        protonup-qt
        winetricks

        # Tools
        gamemode

        # Controllers
        sc-controller

        # Performance monitoring
        nvtopPackages.full
      ];
    };
}
