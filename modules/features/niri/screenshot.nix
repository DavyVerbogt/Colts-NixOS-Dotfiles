{ self, ... }: {

  # Screenshot and screen recording feature.
  # grim/slurp/swappy cover stills; wf-recorder covers video.
  #
  # Two wrapped, Windows-style capture scripts are built in `perSystem`
  # (mirrors the niri.nix/vscodium.nix style: wrap in perSystem, install
  # from the nixosModule) and bound to keys in niri.nix:
  #   - ScreenshotFull:   full-screen grab, piped straight into swappy so a
  #                       real editor window (the "popup") always appears —
  #                       annotate/save/copy from there. Deliberately does
  #                       NOT rely on notify-send/a notification daemon,
  #                       since that's an extra runtime dependency (mako/
  #                       dunst/Noctalia's own service) that may not be
  #                       registered, which was silently swallowing the
  #                       feedback before.
  #   - ScreenshotRegion: interactive region select (slurp) -> swappy for
  #                       annotate/save/copy (like Win+Shift+S's Snip UI).
  # Alt+Print keeps niri's native `screenshot-window` action (niri.nix) —
  # that one already worked and wasn't part of the ask.
  flake.nixosModules.screenshot =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        grim # Wayland screenshot capture
        slurp # interactive region selector (used by grim/swappy)
        swappy # annotate and save screenshots after capture
        wf-recorder # Wayland screen recorder
        self.packages.${pkgs.stdenv.hostPlatform.system}.ScreenshotFull
        self.packages.${pkgs.stdenv.hostPlatform.system}.ScreenshotRegion
      ];
    };

  perSystem = { pkgs, ... }: {

    packages.ScreenshotFull = pkgs.writeShellScriptBin "screenshot-full" ''
      set -euo pipefail
      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"
      file="$dir/Screenshot_$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S).png"

      ${pkgs.grim}/bin/grim - | ${pkgs.swappy}/bin/swappy -f - -o "$file"
    '';

    packages.ScreenshotRegion = pkgs.writeShellScriptBin "screenshot-region" ''
      set -euo pipefail
      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"
      file="$dir/Screenshot_$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S).png"

      # slurp exits non-zero if the user cancels (Esc) — just bail quietly.
      geometry=$(${pkgs.slurp}/bin/slurp) || exit 0

      ${pkgs.grim}/bin/grim -g "$geometry" - \
        | ${pkgs.swappy}/bin/swappy -f - -o "$file"
    '';
  };
}
