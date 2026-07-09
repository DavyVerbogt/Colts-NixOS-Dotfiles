{ config, lib, ... }: {
  config = lib.mkIf (config.theme.profile == "cyberpunk") {
    desktop.gtkTheme    = "adw-gtk3-dark";
    desktop.iconTheme   = "candy-icons";
    desktop.cursorTheme = "Banana";

    # Let useWallpaperColors + Noctalia's Material Gen drive the scheme.
    theme.noctaliaPredefinedScheme = "";

    # These aren't invented — they're the two neon palettes that already
    # exist independently in niri.nix's focus-ring and steam.nix's MangoHud
    # config, reconciled to one canonical set (the purples were close but
    # not identical: #ff0080/#bf00ff vs #bf5fff). Expanded with MangoHud's
    # remaining colors (foreground/red/yellow/blue) so home/kitty.nix has a
    # full terminal palette that's still entirely sourced from your repo,
    # not newly invented.
    theme.palette = {
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
