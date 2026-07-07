{ ... }: {
  # Amethyst is distributed as a Type 2 AppImage, but nixpkgs' static
  # extraction (appimageTools.wrapType2) fails on this release — the
  # AppImage's embedded runtime can't find its squashfs section under the
  # build sandbox, even though the same file runs fine standalone. Fix is to
  # skip build-time extraction and run via appimage-run at runtime.
  flake.nixosModules.amm =
    { pkgs, ... }:
    let
      amethystAppImage = pkgs.fetchurl {
        url = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases/download/v1.3.12/AmethystModManager-1.3.12-x86_64.AppImage";
        hash = "sha256-oCoLjiMLYqLtaqUK5FxT1HWgHmOIjTzO7JWTYKWwdB4=";
      };

      amethyst = pkgs.writeShellScriptBin "amethyst-mod-manager" ''
        exec ${pkgs.appimage-run}/bin/appimage-run ${amethystAppImage} "$@"
      '';

      # Ship the .desktop entry as a real package so it lands in
      # …/share/applications (what app launchers scan) instead of
      # /etc/xdg/applications (which only registers protocol handlers).
      # Also carries the nxm scheme handler + Categories so it shows as a
      # normal launchable app.
      amethystDesktop = pkgs.makeDesktopItem {
        name = "amethyst";
        desktopName = "Amethyst Mod Manager";
        exec = "${amethyst}/bin/amethyst-mod-manager %u";
        categories = [
          "Game"
          "Utility"
        ];
        mimeTypes = [
          "x-scheme-handler/nxm"
          "x-scheme-handler/nxm-protocol"
        ];
      };
    in
    {
      environment.systemPackages = [
        amethyst
        amethystDesktop
        pkgs.appimage-run
      ];
    };
}
