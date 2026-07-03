{ config, ... }: {

  # Steam and Spotify (Spicetify's target) are both CEF-based clients that,
  # on Linux, read cursor theme via GSettings/dconf
  # (org.gnome.desktop.interface cursor-theme) rather than XCURSOR_PATH
  # (desktop/cursor.nix) or GTK's settings.ini (desktop/gtk-settings.nix).
  # niri has no GNOME session to ever populate that dconf database, so
  # GSettings falls back to its schema default ("Adwaita") for these apps
  # specifically, even though everything reading XCURSOR_* or settings.ini
  # picks up Banana correctly. This gives dconf an actual system-wide
  # default so those lookups resolve to the same theme as everything else.
  #
  # Note: Steam's own window chrome (library, Big Picture) has a
  # long-standing history of ignoring the system cursor theme entirely
  # regardless of GSettings/XCURSOR — this may not fully resolve for Steam
  # even though it should for Spotify/Spicetify.
  flake.nixosModules.dconfCursor =
    { pkgs, ... }:
    let
      inherit (config.desktop) cursorTheme cursorSize;
    in
    {
      programs.dconf.enable = true;

      environment.etc."dconf/db/local.d/00-cursor".text = ''
        [org/gnome/desktop/interface]
        cursor-theme='${cursorTheme}'
        cursor-size=${toString cursorSize}
      '';

      # Explicitly trigger a dconf rebuild on activation, rather than relying
      # on the dconf module's file-watcher picking up the change on its own.
      system.activationScripts.dconfCursor = ''
        ${pkgs.dconf}/bin/dconf update
      '';
    };
}
