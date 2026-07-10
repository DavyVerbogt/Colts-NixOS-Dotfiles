{ self, ... }: {

  flake.nixosModules.ws01-nixConfig = { ... }: {

    imports = with self.nixosModules; [
      ws01-nixHardware

      # system
      boot
      networking
      locale
      users
      printing
      nixSettings

      # desktop
      niridesktop
      audio
      pipewireLatency
      sddm
      qylock
      nvidia
      nerdFont
      themeSwitch

      # dev
      dev

      # games & gamedev
      steam
      minecraft
      psx
      amm
      blender
      blockbench
      godot
      unity
      vrcc

      # media
      spicetify
      vesktop
      zen

      # peripherals
      bazecor
      bluetooth

      # home-manager
      homeManagerBase
    ];

    networking.hostName = "ws01-nix";

    system.stateVersion = "26.05";
  };
}
