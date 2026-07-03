{ lib, ... }: {
  flake.nixosModules.amm =
    { pkgs, ... }:
    let
      amethyst = pkgs.appimageTools.wrapType2 {
        pname = "amethyst-mod-manager";
        version = "1.3.12";
        src = pkgs.fetchurl {
          url = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases/download/v1.3.12/Amethyst-MM-x86_64.AppImage";
          hash = lib.fakeHash;
        };
      };
    in
    {
      environment.systemPackages = [ amethyst ];

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
