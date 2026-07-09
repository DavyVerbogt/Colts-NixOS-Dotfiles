{ config, ... }: {
  # Home-Manager-native cursor application via HM's unified
  # home.pointerCursor — the current option (supersedes the older split
  # xsession.pointerCursor / manual gtk.cursorTheme approach). With
  # gtk.enable = true, HM derives gtk.cursorTheme from this automatically
  # (see home-manager/modules/config/home-cursor.nix), so it's deliberately
  # not also set by hand here — that would just be redundant.
  #
  # Doesn't replace desktop/cursor.nix's option declaration (same reason as
  # gtk.nix) or its XCURSOR_PATH fix for Steam/Spicetify/Claude Desktop —
  # that was a hard-won, verified fix for XWayland/Qt/Electron cursor
  # lookup, and isn't being deleted on the assumption that HM's own
  # mechanism fully reproduces it. This module is additive on top of it.
  flake.homeManagerModules.cursor = { pkgs, ... }: {
    home.pointerCursor = {
      name = config.desktop.cursorTheme;
      size = config.desktop.cursorSize;
      package = pkgs.banana-cursor;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
