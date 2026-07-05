{ ... }: {
  # Amethyst is distributed as a Type 2 AppImage, but nixpkgs' static
  # extraction (appimageTools.wrapType2, which runs appimage-exec.sh inside
  # a sandboxed build) fails on this particular release — the AppImage's own
  # embedded runtime can't find its squashfs section under that sandbox,
  # even though the exact same file runs fine standalone
  # (--appimage-extract-and-run works outside Nix). Since the file itself is
  # valid, the fix is to skip build-time extraction and run it via
  # appimage-run instead, which uses the same self-extraction mechanism that
  # already proved to work. Still fully reproducible: same fetchurl + pinned
  # hash as before, just no longer relying on the sandboxed extraction step.
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
    in
    {
      environment.systemPackages = [
        amethyst
        pkgs.appimage-run
      ];

      # NXM protocol handler so browser one-click installs route to Amethyst.
      # Default-application registration for this now lives in
      # desktop/mimeapps.nix (which owns /etc/xdg/mimeapps.list globally).
      environment.etc."xdg/applications/amethyst.desktop".text = ''
        [Desktop Entry]
        Name=Amethyst Mod Manager
        Exec=${amethyst}/bin/amethyst-mod-manager %u
        Type=Application
        MimeType=x-scheme-handler/nxm;x-scheme-handler/nxm-protocol;
      '';
    };
}
