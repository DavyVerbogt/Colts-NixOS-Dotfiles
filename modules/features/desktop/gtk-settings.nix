{ config, ... }: {

  flake.nixosModules.gtkSettings =
    { pkgs, ... }:
    let
      inherit (config.desktop)
        gtkTheme
        iconTheme
        cursorTheme
        cursorSize
        ;
      settingsIni = ''
        [Settings]
        gtk-theme-name=${gtkTheme}
        gtk-icon-theme-name=${iconTheme}
        gtk-cursor-theme-name=${cursorTheme}
        gtk-cursor-theme-size=${toString cursorSize}
        gtk-application-prefer-dark-theme=1
      '';
    in
    {
      gtk.iconCache.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      environment.etc."gtk-3.0/settings.ini".text = settingsIni;
      environment.etc."gtk-4.0/settings.ini".text = settingsIni;
    };
}
