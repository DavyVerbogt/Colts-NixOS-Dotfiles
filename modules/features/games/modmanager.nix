{ lib, ... }: {
  flake.nixosModules.amm =
    { pkgs, ... }:
    let
      appimage = pkgs.fetchurl {
        url = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases/download/v1.3.12/AmethystModManager-1.3.12-x86_64.AppImage";
        hash = "sha256-oCoLjiMLYqLtaqUK5FxT1HWgHmOIjTzO7JWTYKWwdB4=";
      };
      icon = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/ChrisDKN/Amethyst-Mod-Manager/main/src/icons/title-bar.png";
        hash = "sha256-RonqF4Osw4nZgz6vYgH71Q8ozhU3WiUAURTnSnDfv0U=";
      };

      # Copy AppImage into its own derivation with +x so it's executable
      executableAppimage = pkgs.runCommand "amethyst-appimage" { } ''
        mkdir -p $out
        install -m755 ${appimage} $out/AmethystModManager.AppImage
      '';

      wrapper = pkgs.writeShellScript "amethyst-mod-manager" ''
        exec ${executableAppimage}/AmethystModManager.AppImage "$@"
      '';

      amethyst = pkgs.runCommand "amethyst-mod-manager" { } ''
        mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps

        ln -s ${wrapper} $out/bin/amethyst-mod-manager

        cat > $out/share/applications/amethyst.desktop << EOF
        [Desktop Entry]
        Name=Amethyst Mod Manager
        Exec=$out/bin/amethyst-mod-manager %u
        Type=Application
        Icon=amethyst-mod-manager
        Categories=Game;Utility;
        MimeType=x-scheme-handler/nxm;x-scheme-handler/nxm-protocol;
        EOF

        cp ${icon} $out/share/icons/hicolor/256x256/apps/amethyst-mod-manager.png
      '';
    in
    {
      environment.systemPackages = [ amethyst ];

      environment.etc."xdg/mimeapps.list".text = ''
        [Default Applications]
        x-scheme-handler/nxm=amethyst.desktop
        x-scheme-handler/nxm-protocol=amethyst.desktop
      '';
    };
}
