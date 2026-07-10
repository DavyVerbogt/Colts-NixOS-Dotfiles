{ ... }: {
  # Nord-based work theme. Palette is the genuine Arctic Ice Studio Nord
  # set, carried over from the old profiles/productivity.nix.
  theme.themes.productivity = {
    gtkTheme = "adw-gtk3-dark";
    iconTheme = "candy-icons";
    cursorTheme = "Banana";

    # Still NOT verified against Noctalia's actual preset list the way
    # "Gruvbox" is — check Noctalia's settings UI for the real preset
    # names and adjust if "Nord" isn't one.
    noctaliaPredefinedScheme = "Nord";
    darkMode = true;

    # wallpaper/productivity/ — bright/scenic/low-drama set.
    wallpaperDir = "productivity";
    fillColor = "#2e3440"; # Nord0, palette.void

    # Cozy/quiet SDDM pool (names verified against the pinned qylock themes/).
    sddmThemes = [
      "girl-coffee"
      "pixel-coffee"
      "pixel-waterfall"
      "pixel-emerald"
      "women-umbrella"
    ];
    qylockTheme = "girl-coffee";

    terminalOpacity = 0.95; # barely-there — legibility over style
    spicetifyColorScheme = "Nord"; # matches the palette below

    niri = {
      inactiveColor = "#3b4252"; # Nord1
      gaps = 6;
      cornerRadius = 8;
      windowOpacity = 1.0; # fully opaque — text legibility over style
      appOpacity = { }; # no translucent apps in work mode
      pipOpacity = 1.0; # opaque PiP too (blur still forced off by its rule)
      glitchShader = false;
    };

    palette = {
      accent     = "#88c0d0"; # Nord8  (Frost)
      accent2    = "#81a1c1"; # Nord9  (Frost)
      void       = "#2e3440"; # Nord0  (Polar Night) — Nord's actual background
      foreground = "#d8dee9"; # Nord4  (Snow Storm)
      red        = "#bf616a"; # Nord11 (Aurora)
      yellow     = "#ebcb8b"; # Nord13 (Aurora)
      green      = "#a3be8c"; # Nord14 (Aurora)
      cyan       = "#8fbcbb"; # Nord7  (Frost)
      blue       = "#5e81ac"; # Nord10 (Frost)
    };
  };
}
