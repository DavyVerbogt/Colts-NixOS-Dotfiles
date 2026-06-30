{ inputs, ... }: {

  perSystem = { pkgs, ... }: {

    packages.NoctaliaConf =
      let
        jsonSettings = (builtins.fromJSON (builtins.readFile ./noctalia.json)).settings;

        sweetThemeSwitch = pkgs.writeShellScript "sweet-theme-switch" ''
          current=$(${pkgs.glib}/bin/gsettings get org.gnome.desktop.interface color-scheme)
          if [ "$current" = "'prefer-dark'" ]; then
            ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "Sweet-Dark"
          else
            ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "Sweet"
          fi
        '';
      in
      inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
        inherit pkgs;
        settings = jsonSettings // {
          hooks = (jsonSettings.hooks or { }) // {
            enabled = true;
            darkModeChange = "${sweetThemeSwitch}";
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
