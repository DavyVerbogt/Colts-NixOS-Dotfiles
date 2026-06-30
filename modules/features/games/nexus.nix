{ pkgs, ... }:
let
  nexusModsApp = pkgs.appimageTools.wrapType2 {
    pname = "nexusmods-app";
    version = "0.10.0"; # bump to match the AppImage you download
    src = pkgs.fetchurl {
      url = "https://github.com/Nexus-Mods/NexusMods.App/releases/latest/download/nexusmods-app.AppImage";
      sha256 = pkgs.lib.fakeHash;
    };
  };
in
{
  flake.nixosModules.nexus = { ... }: {
    environment.systemPackages = [
      nexusModsApp
    ];

    # NXM protocol handler — lets "Mod Manager Download" buttons on
    # Nexus Mods open directly into the Nexus Mods App
    environment.etc."xdg/mimeapps.list".text = ''
      [Default Applications]
      x-scheme-handler/nxm=nexusmods-app.desktop
    '';
  };
}
