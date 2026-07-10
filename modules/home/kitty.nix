{ config, ... }: {

  # Kitty's color theme, sourced from theme.palette (theming/core.nix +
  # theming/profiles/*.nix) — the same source of truth niri's focus-ring
  # and steam's MangoHud already read from. Lives in Home Manager rather
  # than a system-level /etc/xdg/kitty/kitty.conf because kitty config is
  # genuinely per-user preference (same category as VSCodium's
  # settings.json) — a system-level file only applies when the user has no
  # ~/.config/kitty/kitty.conf at all, which breaks the moment anyone edits
  # kitty settings by hand.
  #
  # This reads the *fixed* profile palette, not Noctalia's own live
  # wallpaper-driven Material Gen colors. noctalia.json already lists
  # "kitty" as an active template, meaning Noctalia separately believes
  # it's generating its own kitty colors on scheme change, to a path that
  # was never verified. The two could end up fighting over the same file.
  # This is the reliable, guaranteed-to-build option since it doesn't
  # depend on that unverified Noctalia internal; if you'd rather have
  # wallpaper-driven colors reach the terminal too, check what file
  # Noctalia actually writes after a scheme change and `include` it from
  # kitty.conf instead of (or alongside, with this one loading first)
  # setting `settings` directly here.
  #
  # NOTE: programs.kitty.enable also pulls in the kitty package itself via
  # home.packages — harmless alongside features/niri/kitty.nix's existing
  # system-level environment.systemPackages install (same store path,
  # deduplicated by Nix, not two real copies). That file still owns
  # $TERMINAL and the system-wide install; this one only owns the theme.
  flake.homeManagerModules.kitty = { lib, ... }: {
    programs.kitty = {
      enable = true;
      settings = {
        # Background-only transparency from the active theme
        # (theme.current.terminalOpacity) — kitty fades just the background,
        # text stays crisp, which is why the terminal is deliberately NOT in
        # the theme's niri.appOpacity window rules. floatToString (toJSON
        # under the hood) renders "0.85", not toString's "0.850000".
        # dynamic_background_opacity lets kitty's Ctrl+Shift+A+m/l adjust
        # it live without a rebuild.
        background_opacity = lib.strings.floatToString (config.theme.current.terminalOpacity or 1.0);
        dynamic_background_opacity = true;

        background = config.theme.palette.void or "#0d0d1a";
        foreground = config.theme.palette.foreground or "#dde4ff";
        cursor = config.theme.palette.accent or "#ff0080";
        selection_background = config.theme.palette.accent or "#ff0080";
        selection_foreground = config.theme.palette.void or "#0d0d1a";

        # normal 0-7
        color0 = config.theme.palette.void or "#0d0d1a"; # black
        color1 = config.theme.palette.red or "#ff3030";
        color2 = config.theme.palette.green or "#39ff14";
        color3 = config.theme.palette.yellow or "#ff9500";
        color4 = config.theme.palette.blue or "#5b8af5";
        color5 = config.theme.palette.accent or "#ff0080"; # magenta
        color6 = config.theme.palette.cyan or "#00e5ff";
        color7 = config.theme.palette.foreground or "#dde4ff"; # white

        # bright 8-15 — color8/color15 (bright black/white) stay fixed
        # across every profile since `ls`, git diffs, etc. rely on that
        # contrast existing regardless of theme; the rest reuse the normal
        # intensity, which is a common, intentional simplification.
        color8 = "#4d4d4d";
        color9 = config.theme.palette.red or "#ff3030";
        color10 = config.theme.palette.green or "#39ff14";
        color11 = config.theme.palette.yellow or "#ff9500";
        color12 = config.theme.palette.blue or "#5b8af5";
        color13 = config.theme.palette.accent2 or "#bf00ff"; # bright magenta
        color14 = config.theme.palette.cyan or "#00e5ff";
        color15 = "#ffffff";
      };
    };
  };
}
