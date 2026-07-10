{ ... }: {
  flake.nixosModules.boot = { pkgs, ... }: {
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
  };
}
