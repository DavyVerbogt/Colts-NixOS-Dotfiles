{ self, inputs, ... }: {

  flake.nixosModules.vesktop = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.VesktopConf
    ];
  };

  perSystem = { pkgs, lib, ... }: {
    packages.VesktopConf =
      let
        vesktopSettings = pkgs.writeText "vesktop-settings.json" (
          builtins.toJSON {
            minimizeToTray = false;
            discordBranch = "stable";
            customTitleBar = true;
            hardwareAcceleration = true;
          }
        );
        vencordSettings = pkgs.writeText "vencord-settings.json" (
          builtins.toJSON {
            autoUpdate = true;
            plugins = {
              NoDevtoolsWarning = {
                enabled = true;
              };
            };
          }
        );
      in
      pkgs.symlinkJoin {
        name = "vesktop-configured";
        paths = [ pkgs.vesktop ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/vesktop \
            --run 'mkdir -p "''${XDG_CONFIG_HOME:-$HOME/.config}/vesktop/settings"' \
            --run 'install -m600 ${vesktopSettings} "''${XDG_CONFIG_HOME:-$HOME/.config}/vesktop/settings.json"' \
            --run 'install -m600 ${vencordSettings}  "''${XDG_CONFIG_HOME:-$HOME/.config}/vesktop/settings/settings.json"'
        '';
      };
  };
}
