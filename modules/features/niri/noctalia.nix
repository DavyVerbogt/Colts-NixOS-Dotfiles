{ inputs, ... }: {

  perSystem = { pkgs, self', ... }: {

    packages.NoctaliaConf =
      let
        jsonSettings = (builtins.fromJSON (builtins.readFile ./noctalia.json)).settings;

        adwGtk3ThemeSwitch = pkgs.writeShellScript "adw-gtk3-theme-switch" ''
          current=$(${pkgs.glib}/bin/gsettings get org.gnome.desktop.interface color-scheme)
          if [ "$current" = "'prefer-dark'" ]; then
            ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
          else
            ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"
          fi
        '';
      in
      inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
        inherit pkgs;
        settings = jsonSettings // {
          hooks = (jsonSettings.hooks or { }) // {
            enabled = true;
            darkModeChange = "${adwGtk3ThemeSwitch}";
            wallpaperChange = "${self'.packages.MatugenWallpaperHook}";
          };
        };
      };
  };

  flake.nixosModules.noctalia =
    { pkgs, ... }:
    let
      lockCmd = "qs -c noctalia-shell ipc call lockScreen lock";
      suspendCmd = "qs -c noctalia-shell ipc call sessionMenu lockAndSuspend";

      idleScript = pkgs.writeShellScript "swayidle-start" ''
        exec ${pkgs.swayidle}/bin/swayidle -w \
          timeout 240 'niri msg action power-off-monitors' \
          timeout 300 '${lockCmd}' \
          timeout 600 '${suspendCmd}' \
          before-sleep '${lockCmd}'
      '';
    in
    {
      environment.systemPackages = [ pkgs.swayidle ];

      systemd.user.services.swayidle = {
        description = "Idle manager for Wayland";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${idleScript}";
          Environment = "PATH=/run/current-system/sw/bin:/run/wrappers/bin";
          Restart = "on-failure";
        };
      };
    };
}
