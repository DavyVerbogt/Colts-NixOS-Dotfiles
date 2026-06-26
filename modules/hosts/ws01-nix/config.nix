{ self, inputs, ... }: {

  flake.nixosModules.ws01-nixConfig = { config, pkgs, ... }: {

    imports = [
      self.nixosModules.ws01-nixHardware
      self.nixosModules.niridesktop
      self.nixosModules.dev
      self.nixosModules.steam
      self.nixosModules.spicetify
      self.nixosModules.vesktop
      self.nixosModules.zen
    ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelPackages = pkgs.linuxPackages_latest;

    networking.hostName = "nixos";

    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Amsterdam";

    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "nl_NL.UTF-8";
      LC_IDENTIFICATION = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_NAME = "nl_NL.UTF-8";
      LC_NUMERIC = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
      LC_TELEPHONE = "nl_NL.UTF-8";
      LC_TIME = "nl_NL.UTF-8";
    };

    services.xserver.enable = true;

    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    services.xserver.xkb = {
      layout = "us";
      variant = "euro";
    };

    services.printing.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

    };

    users.users."colt" = {
      shell = pkgs.fish;
      isNormalUser = true;
      description = "Colt";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [
        kdePackages.kate
      ];
    };

    programs.firefox.enable = true;
    nixpkgs.config.allowUnfree = true;
    programs.fish.enable = true;
    programs.direnv.enableFishIntegration = true;

    environment.systemPackages = with pkgs; [
      firefox

    ];
    system.stateVersion = "26.05";
  };
}
