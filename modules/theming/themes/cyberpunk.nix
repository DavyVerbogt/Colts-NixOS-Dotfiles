{ ... }: {
  # Neon-noir default. Palette history: reconciled from the two neon sets
  # that already existed in niri.nix's focus-ring and steam.nix's MangoHud
  # config — nothing here is invented (see the per-key comments).
  theme.themes.cyberpunk = {
    gtkTheme = "adw-gtk3-dark";
    iconTheme = "candy-icons";
    cursorTheme = "Banana";

    # Empty = let useWallpaperColors + Noctalia's Material Gen drive the
    # scheme from whatever wallpaper is up.
    noctaliaPredefinedScheme = "";
    darkMode = true;

    # wallpaper/cyberpunk/ — the neon/night-city/vivid set.
    wallpaperDir = "cyberpunk";
    fillColor = "#0d0d1a"; # palette.void, was hardcoded #000000 in noctalia.json

    # SDDM boot pool. All names verified against the pinned qylock rev's
    # themes/ directory — the old list's "honkai-star-rail" and
    # "reverse-1999" don't exist there (it's star-rail / R1999_1 / R1999_2),
    # so those picks were silently falling back to the default theme.
    # minecraft/terraria kept here so every entry of the old pool still
    # lives somewhere.
    sddmThemes = [
      "pixel-cyberpunk"
      "pixel-night-city"
      "pixel-dusk-city"
      "pixel-skyscrapers"
      "nier-automata"
      "star-rail"
      "R1999_1"
      "R1999_2"
      "minecraft"
      "terraria"
    ];
    qylockTheme = "nier-automata";

    # Background-only kitty transparency — text stays crisp.
    terminalOpacity = 0.85;
    # Spicetify "text" theme scheme — neon purples/blues, closest fit here.
    spicetifyColorScheme = "TokyoNight";

    niri = {
      inactiveColor = "#2a2a2a"; # was hardcoded in niri.nix
      gaps = 8;
      cornerRadius = 12;
      # Windows are opaque by default now (the old global 0.90 made
      # EVERYTHING see-through); only the picked apps below go translucent.
      windowOpacity = 1.0;
      appOpacity = {
        # Verify with `niri msg windows` if one stays opaque — the
        # alternations cover the app-id spellings these ship with
        # (XWayland apps like Steam match on WM_CLASS).
        "^(codium|VSCodium)$" = 0.90; # VSCodium
        "^(spotify|Spotify)$" = 0.90; # Spotify/Spicetify
        "^(thunar|Thunar)$" = 0.90; # file manager
        "^(steam|Steam)$" = 0.90; # Steam client
        "^(claude|Claude|claude-desktop)$" = 0.90; # Claude Desktop
        "^(bazecor|Bazecor)$" = 0.90; # Dygma keyboard config
        "^(faugus-launcher|faugus)$" = 0.90; # Faugus Launcher
      };
      pipOpacity = 0.90; # PiP translucent, blur forced off in its rule
      glitchShader = true; # the glitch open/close shaders are this theme's signature
    };

    palette = {
      accent     = "#ff0080"; # niri.nix focus-ring "from"
      accent2    = "#bf00ff"; # niri.nix focus-ring "to"
      cyan       = "#00e5ff"; # steam.nix MangoHud gpu/engine color
      void       = "#0d0d1a"; # steam.nix MangoHud background
      green      = "#39ff14"; # steam.nix MangoHud fps-good color
      foreground = "#dde4ff"; # steam.nix MangoHud text_color
      red        = "#ff3030"; # steam.nix MangoHud fps-bad color
      yellow     = "#ff9500"; # steam.nix MangoHud fps-warn color
      blue       = "#5b8af5"; # steam.nix MangoHud ram_color
    };
  };
}
