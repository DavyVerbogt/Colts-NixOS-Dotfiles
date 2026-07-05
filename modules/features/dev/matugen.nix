{ ... }: {
  flake.nixosModules.matugen =
    { pkgs, ... }:
    let
      # Real upstream templates, not hand-guessed syntax — input_path points
      # straight at the fetched, immutable store path, so there's no need to
      # also symlink a local ~/.config/matugen/templates/ copy.
      vscodeColorsTemplate = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/InioX/matugen-themes/main/templates/vscode-colors";
        sha256 = pkgs.lib.fakeHash; # first build fails with the real hash, paste it in
      };
      vscodeColorsJsonTemplate = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/InioX/matugen-themes/main/templates/vscode-colors.json";
        sha256 = pkgs.lib.fakeHash;
      };

      matugenConfig = pkgs.writeText "matugen-config.toml" ''
        [config]

        [templates.vscode-raw]
        input_path = '${vscodeColorsTemplate}'
        output_path = '~/.cache/matugen/vscode-colors'

        [templates.vscode-json]
        input_path = '${vscodeColorsJsonTemplate}'
        output_path = '~/.cache/matugen/vscode-colors.json'
      '';
    in
    {
      environment.systemPackages = [ pkgs.matugen ];

      # config.toml is entirely Nix-owned — matugen only ever writes to the
      # output_paths above, never back to its own config — so a forced
      # symlink here is safe and keeps it fully declarative.
      systemd.user.tmpfiles.rules = [
        "L+ %h/.config/matugen/config.toml - - - - ${matugenConfig}"
      ];
    };

  perSystem = { pkgs, ... }: {
    # The actual hook script Noctalia calls on wallpaper change. Runs matugen
    # against whatever wallpaper path Noctalia passes it as $1 — verify this
    # is actually the argument contract by testing; I couldn't confirm it
    # from Noctalia's docs, only inferred it from the general
    # swww/hyprpaper-hook convention this ecosystem tends to follow.
    packages.MatugenWallpaperHook = pkgs.writeShellScript "matugen-wallpaper-hook" ''
      ${pkgs.matugen}/bin/matugen image "$1"
    '';
  };
}
