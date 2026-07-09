{ config, lib, ... }: {
  config = lib.mkIf (config.theme.profile == "minimal") {
    desktop.gtkTheme    = "adw-gtk3-dark";
    desktop.iconTheme   = "Adwaita";
    desktop.cursorTheme = "Banana";

    # "Gruvbox" is confirmed valid — it's what was already hardcoded in
    # noctalia.json before this file existed.
    theme.noctaliaPredefinedScheme = "Gruvbox";

    theme.palette = {
      accent     = "#4a86e8";
      accent2    = "#4a86e8";
      void       = "#1a1a1a";
      # New, designed-now values (unlike cyberpunk's, these aren't pulled
      # from anywhere already in your repo) — a calm, desaturated set,
      # used by both home/kitty.nix's terminal theme and steam.nix's
      # MangoHud overlay, which now follows theme.palette consistently
      # instead of always staying neon (see steam.nix's updated comment).
      foreground = "#d8d8d8";
      red        = "#e05561";
      yellow     = "#d2b55b";
      green      = "#7fbf7f";
      cyan       = "#5fb3b3";
      blue       = "#4a86e8";
    };
  };
}
