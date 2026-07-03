{ config, ... }: {

  # GSettings/dconf defaults for apps that don't read XCURSOR_PATH
  # (desktop/cursor.nix) or GTK's settings.ini (desktop/gtk-settings.nix) —
  # notably Steam and Spotify/Spicetify, which are CEF-based and query
  # org.gnome.desktop.interface directly.
  #
  # gsettings-desktop-schemas provides the actual schema definitions for
  # org.gnome.desktop.interface (cursor-theme, icon-theme, gtk-theme,
  # color-scheme, etc). Without it installed, every `gsettings` call against
  # that schema fails outright rather than silently no-opping — this is also
  # why Noctalia's own dark/light-mode hook (niri/noctalia.nix, which calls
  # `gsettings set org.gnome.desktop.interface gtk-theme ...` on toggle) was
  # failing: standard GNOME-based distros pull this package in automatically
  # as a dependency of the desktop environment, but a minimal niri setup
  # never gets it unless something installs it explicitly.
  flake.nixosModules.dconfDefaults =
    { pkgs, ... }:
    let
      inherit (config.desktop) cursorTheme cursorSize iconTheme gtkTheme;
    in
    {
      environment.systemPackages = [ pkgs.gsettings-desktop-schemas ];

      programs.dconf.enable = true;

      environment.etc."dconf/db/local.d/00-desktop-interface".text = ''
        [org/gnome/desktop/interface]
        cursor-theme='${cursorTheme}'
        cursor-size=${toString cursorSize}
        icon-theme='${iconTheme}'
        gtk-theme='${gtkTheme}'
      '';

      # Explicitly trigger a dconf rebuild on activation, rather than relying
      # on the dconf module's file-watcher picking up the change on its own.
      system.activationScripts.dconfDefaults = ''
        ${pkgs.dconf}/bin/dconf update
      '';
    };
}
