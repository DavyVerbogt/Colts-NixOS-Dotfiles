{ config, ... }: {

  # Renders the settings.ini files GTK2/3/4 apps read for theme/icon/cursor
  # selection on Wayland (via gsettings) and X11/XWayland. This is the one
  # place all three theming concerns (desktop/theme.nix, desktop/icons.nix,
  # desktop/cursor.nix) get combined, since it's a single generated artifact
  # and environment.etc.<name>.text can't be split across modules.
  #
  # Also owns the plumbing needed for the theme to actually take effect:
  # - gtk.iconCache.enable: without it candy-icons/Sweet won't be found by
  #   GTK apps or Thunar.
  # - xdg-desktop-portal-gtk: must be running for GTK apps on Wayland to
  #   read org.gnome.desktop.interface via gsettings (e.g. the Noctalia
  #   dark/light hook).
  flake.nixosModules.gtkSettings =
    { pkgs, ... }:
    let
      inherit (config.desktop) gtkTheme iconTheme cursorTheme cursorSize;
      settingsIni = ''
        [Settings]
        gtk-theme-name=${gtkTheme}
        gtk-icon-theme-name=${iconTheme}
        gtk-cursor-theme-name=${cursorTheme}
        gtk-cursor-theme-size=${toString cursorSize}
        gtk-application-prefer-dark-theme=1
      '';
    in
    {
      gtk.iconCache.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      environment.etc."gtk-3.0/settings.ini".text = settingsIni;
      environment.etc."gtk-4.0/settings.ini".text = settingsIni;
    };
}
