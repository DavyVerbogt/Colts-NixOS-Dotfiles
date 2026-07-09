{ lib, ... }: {

  # Central device/theme switches, same options/config split already used by
  # desktop/cursor.nix, desktop/theme.nix, desktop/icons.nix. Every other
  # theming or per-device file reads these instead of inventing its own.
  #
  # HONEST LIMITATION: like cursor.nix/theme.nix/icons.nix, these are plain
  # flake-parts-level options — a single value shared across the whole
  # flake, not something nixosSystem evaluates separately per host. That's
  # fine today (one host, ws01-nix). If you ever add a second host on the
  # SAME system architecture (x86_64-linux), it will share these same
  # values and the same perSystem-built NiriConf/NoctaliaConf packages
  # unless you refactor those wrap calls to happen per-host instead of
  # per-system. Not needed yet — flagging so it isn't a surprise later.

  options.device.class = lib.mkOption {
    type = lib.types.enum [ "desktop" "laptop" ];
    default = "desktop";
    description = "Form factor. Gates mouse/font/theme defaults across other modules.";
  };

  options.theme.profile = lib.mkOption {
    type = lib.types.enum [ "cyberpunk" "minimal" "productivity" ];
    default = "cyberpunk";
    description = "Active theme profile — change the default above until true per-host support exists (see note).";
  };

  options.theme.palette = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Canonical named hex colors for the active theme.profile — set by theming/profiles/*.nix.";
  };

  options.theme.noctaliaPredefinedScheme = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = ''
      Value fed into Noctalia's colorSchemes.predefinedScheme. Empty string
      lets useWallpaperColors + Material Gen drive it instead (cyberpunk's
      default). niri/noctalia.nix reads this instead of the value that used
      to be hardcoded straight into noctalia.json.
    '';
  };

  options.desktop.fontScale = lib.mkOption {
    type = lib.types.float;
    default = 1.0;
    description = "Multiplier fed into Noctalia's ui.fontDefaultScale/fontFixedScale.";
  };
}
