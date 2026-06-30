{ ... }:
{
  flake.modules.nixos =
    { pkgs, lib, ... }:
    let
      nexusModsApp = pkgs.appimageTools.wrapType2 {
        pname = "nexusmods-app";
        version = "0.10.0";
        src = pkgs.fetchurl {
          url = "https://github.com/Nexus-Mods/NexusMods.App/releases/latest/download/nexusmods-app.AppImage";
          sha256 = pkgs.lib.fakeHash;
        };
      };
    in
    {
      environment.systemPackages = [
        nexusModsApp
        (pkgs.makeDesktopItem {
          name = "nexusmods-app";
          desktopName = "Nexus Mods App";
          exec = "${nexusModsApp}/bin/nexusmods-app %u";
          icon = "nexusmods-app";
          categories = [ "Game" ];
          mimeTypes = [ "x-scheme-handler/nxm" ];
        })
      ];

      environment.etc."xdg/mimeapps.list".text = ''
        [Default Applications]
        x-scheme-handler/nxm=nexusmods-app.desktop
      '';
    };
}
