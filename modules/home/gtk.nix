{ config, ... }: {
  # Home-Manager-native GTK theme/icon-theme application — mirrors
  # desktop/theme.nix + desktop/icons.nix's values, doesn't replace their
  # option declarations (niri.nix's perSystem-built NiriConf also reads
  # desktop.gtkTheme, so the option itself has to stay flake-parts-level).
  # This is the part that genuinely "goes through Home Manager": writing
  # ~/.config/gtk-{3,4}.0/settings.ini via HM's own gtk module instead of
  # gtk-settings.nix's /etc files. Those /etc files are left in place as a
  # fallback for any account not running this module — in practice this
  # one wins anyway, since GTK reads user config ahead of /etc.
  flake.homeManagerModules.gtk = { pkgs, ... }: {
    gtk = {
      enable = true;
      theme = {
        name = config.desktop.gtkTheme;
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = config.desktop.iconTheme;
        package = pkgs.candy-icons;
      };
    };
  };
}
