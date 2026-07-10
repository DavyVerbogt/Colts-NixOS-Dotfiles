{ ... }: {
  # Calm, desaturated, dark. Palette carried over from the old
  # profiles/minimal.nix (designed there, not sourced from elsewhere in
  # the repo — see that file's original note).
  theme.themes.minimal = {
    gtkTheme = "adw-gtk3-dark";
    iconTheme = "Adwaita";
    cursorTheme = "Banana";

    # "Gruvbox" is confirmed valid — it's what was hardcoded in
    # noctalia.json before the theming system existed.
    noctaliaPredefinedScheme = "Gruvbox";
    darkMode = true;

    # wallpaper/minimal/ — dark/muted/abstract set.
    wallpaperDir = "minimal";
    fillColor = "#1a1a1a"; # palette.void

    # Quiet SDDM pool (names verified against the pinned qylock themes/).
    sddmThemes = [
      "nothing"
      "material-you"
      "winter"
      "forest"
      "field"
      "pixel-rainyroom"
    ];
    qylockTheme = "nothing";

    terminalOpacity = 0.90;
    spicetifyColorScheme = "Gruvbox"; # matches the Noctalia scheme above

    niri = {
      inactiveColor = "#1f1f1f";
      gaps = 8;
      cornerRadius = 8;
      windowOpacity = 1.0; # opaque by default; only the apps below are translucent
      appOpacity = {
        "^(codium|VSCodium)$" = 0.95;
        "^(spotify|Spotify)$" = 0.95;
        "^(thunar|Thunar)$" = 0.95;
        "^(steam|Steam)$" = 0.95;
        "^(claude|Claude|claude-desktop)$" = 0.95;
        "^(bazecor|Bazecor)$" = 0.95;
        "^(faugus-launcher|faugus)$" = 0.95;
      };
      pipOpacity = 0.95;
      glitchShader = false;
    };

    palette = {
      accent     = "#4a86e8";
      accent2    = "#4a86e8";
      void       = "#1a1a1a";
      foreground = "#d8d8d8";
      red        = "#e05561";
      yellow     = "#d2b55b";
      green      = "#7fbf7f";
      cyan       = "#5fb3b3";
      blue       = "#4a86e8";
    };
  };
}
