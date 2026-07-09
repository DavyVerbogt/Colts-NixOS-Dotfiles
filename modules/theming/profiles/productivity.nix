{ config, lib, ... }: {
  config = lib.mkIf (config.theme.profile == "productivity") {
    desktop.gtkTheme    = "adw-gtk3-dark";
    desktop.iconTheme   = "candy-icons";
    desktop.cursorTheme = "Banana";

    # NOT verified against Noctalia's actual preset list the way "Gruvbox"
    # is (that one came straight out of your existing noctalia.json) —
    # check Noctalia's settings UI for the real preset names and adjust.
    theme.noctaliaPredefinedScheme = "Nord";

    # A genuine Nord palette (Arctic Ice Studio), not just Nord-adjacent —
    # matches the noctaliaPredefinedScheme guess above and gives
    # home/kitty.nix's terminal theme and steam.nix's MangoHud a real,
    # coherent scheme instead of arbitrary picks.
    theme.palette = {
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
