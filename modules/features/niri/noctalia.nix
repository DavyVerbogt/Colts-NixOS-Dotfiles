{ self, inputs, ... }: {

  perSystem = { pkgs, ... }: {

    packages.NoctaliaConf =
      let
        jsonSettings = (builtins.fromJSON (builtins.readFile ./noctalia.json)).settings;

        # Switches between Sweet and Sweet-Dark whenever Noctalia toggles dark mode.
        # Noctalia fires this hook after syncGsettings has already updated color-scheme,
        # so we just read that value and set the matching GTK theme name.
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
        # Merge the JSON settings with the hook — the hook path is a nix store path
        # so it can't live in the static JSON file.
        settings = jsonSettings // {
          hooks = (jsonSettings.hooks or { }) // {
            enabled = true;
            darkModeChange = "${sweetThemeSwitch}";
          };
        };
      };
  };
}
