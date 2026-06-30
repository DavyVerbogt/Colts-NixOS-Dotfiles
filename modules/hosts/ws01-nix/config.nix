{ self, inputs, ... }: {

  flake.nixosModules.ws01-nixConfig = { config, pkgs, ... }: {

    imports = [
      self.nixosModules.ws01-nixHardware
      self.nixosModules.niridesktop
      self.nixosModules.dev
      self.nixosModules.steam
      self.nixosModules.minecraft
      self.nixosModules.nvidia
      self.nixosModules.spicetify
      self.nixosModules.vesktop
      self.nixosModules.zen
      inputs.qylock.nixosModules.default
    ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
          useOSProber = true;
          gfxmodeEfi = "1920x1080";
          extraEntries = ''
            # Shutdown
            menuentry "Shutdown" {
              halt
            }

            # Reboot
            menuentry "Reboot" {
              reboot
            }
          '';

          theme =
            let
              src = pkgs.fetchFromGitHub {
                owner = "krypciak";
                repo = "crossgrub";
                rev = "1.0.0";
                hash = "sha256-TDgi9e2/aHngdzFCkx0ykZedP3v4IFKiYJGTcWUo+rk=";
              };
            in
            pkgs.runCommand "crossgrub-theme" { } ''
              mkdir -p $out
              cp ${src}/theme.txt $out/
              cp ${src}/*.pf2 $out/
              cp -r ${src}/assets/* $out/
            '';
        };
      };
      kernelPackages = pkgs.linuxPackages_latest;
    };

    networking = {
      hostName = "nixos";
      networkmanager.enable = true;
    };

    time.timeZone = "Europe/Amsterdam";

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
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
    };

    services = {
      printing.enable = true;
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };
    };

    security.rtkit.enable = true;

    users.users.colt = {
      shell = pkgs.fish;
      isNormalUser = true;
      description = "Colt";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };

    nixpkgs.config.allowUnfree = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    programs.qylock = {
      enable = true;
      theme = "nier-automata"; # fallback only, overridden by the service below
    };

    systemd.services.sddm-random-theme = {
      description = "Randomly select qylock SDDM theme";
      before = [ "display-manager.service" ];
      wantedBy = [ "display-manager.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        themes =
        (
          pixel-coffee
          pixel-dusk-city
          pixel-night-city
          pixel-skyscrapers
          pixel-waterfall
          honkai-star-rail
          minecraft
          nier-automata
          reverse-1999
          terraria
        )
          selected=''${themes[$RANDOM % ''${#themes[@]}]}
          mkdir -p /etc/sddm.conf.d
          printf '[Theme]\nCurrent=%s\n' "$selected" > /etc/sddm.conf.d/random-theme.conf
      '';
    };

    programs = {
      # remove regreet.enable = true
      firefox.enable = true;
      fish.enable = true;
      direnv.enableFishIntegration = true;
    };

    system.stateVersion = "26.05";
  };
}
