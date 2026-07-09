{ self, ... }: {

  # Live, no-rebuild switch for Noctalia's color scheme only. GTK theme,
  # cursor theme, and niri's shader gating are compiled into the system
  # closure via theme.profile (theming/core.nix) and still need that option
  # changed + a rebuild — this script is explicitly the fast partial path,
  # not a full theme switch.
  flake.nixosModules.themeSwitch = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.ThemeSwitch
    ];
  };

  perSystem = { pkgs, ... }: {
    packages.ThemeSwitch = pkgs.writeShellScriptBin "theme-switch" ''
      set -euo pipefail
      case "''${1:-}" in
        cyberpunk|minimal|productivity) ;;
        *) echo "usage: theme-switch {cyberpunk|minimal|productivity}" >&2; exit 1 ;;
      esac
      echo "Switching Noctalia's live color scheme only — GTK/cursor/niri" >&2
      echo "shaders need theme.profile set in theming/core.nix + a rebuild." >&2
      qs -c noctalia-shell ipc call colorScheme setScheme "$1"
    '';
  };
}
