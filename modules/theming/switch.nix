{ self, config, lib, ... }: {

  # Live, no-rebuild switch for Noctalia's color scheme only. Everything
  # else a theme owns (GTK/cursor, wallpaper pool, SDDM pool, qylock,
  # niri visuals) is compiled into the system closure via theme.active
  # (theming/core.nix) and still needs that option changed + a rebuild —
  # this script is explicitly the fast partial path, not a full switch.
  #
  # Accepted names come straight from the theme registry, so a custom
  # theme file under theming/themes/ shows up here automatically. Each
  # theme maps to its own noctaliaPredefinedScheme; the old script passed
  # the profile name itself to setScheme, which only worked by accident
  # when the two happened to coincide.
  flake.nixosModules.themeSwitch = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.ThemeSwitch
    ];
  };

  perSystem = { pkgs, ... }:
    let
      usage = lib.concatStringsSep "|" (lib.attrNames config.theme.themes);
      cases = lib.concatStrings (
        lib.mapAttrsToList (
          name: t:
          if t.noctaliaPredefinedScheme == "" then ''
            ${name})
              note
              echo "'${name}' has no predefined scheme — its colors are wallpaper-driven" >&2
              echo "(useWallpaperColors + Material Gen). Nothing to switch live." >&2
              ;;
          '' else ''
            ${name})
              note
              qs -c noctalia-shell ipc call colorScheme setScheme ${lib.escapeShellArg t.noctaliaPredefinedScheme}
              ;;
          ''
        ) config.theme.themes
      );
    in
    {
      packages.ThemeSwitch = pkgs.writeShellScriptBin "theme-switch" ''
        set -euo pipefail
        note() {
          echo "Switching Noctalia's live color scheme only — wallpaper pool," >&2
          echo "GTK/cursor, SDDM/qylock and niri visuals need theme.active set" >&2
          echo "in theming/core.nix (or your host) + a rebuild." >&2
        }
        case "''${1:-}" in
          ${cases}
          *) echo "usage: theme-switch {${usage}}" >&2; exit 1 ;;
        esac
      '';
    };
}
