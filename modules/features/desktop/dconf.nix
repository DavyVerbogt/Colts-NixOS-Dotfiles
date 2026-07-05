{ config, ... }: {
  flake.nixosModules.dconfDefaults =
    { pkgs, ... }:
    let
      inherit (config.desktop)
        cursorTheme
        cursorSize
        iconTheme
        gtkTheme
        ;
    in
    {
      environment.systemPackages = [ pkgs.gsettings-desktop-schemas ];

      programs.dconf.enable = true;

      environment.etc."dconf/db/local.d/00-desktop-interface".text = ''
        [org/gnome/desktop/interface]
        cursor-theme='${cursorTheme}'
        cursor-size=${toString cursorSize}
        icon-theme='${iconTheme}'
        gtk-theme='${gtkTheme}'
      '';

      # Locks make these four keys authoritative regardless of file-merge
      # ordering or a stale value already sitting in the user's dconf db —
      # which is exactly how icon-theme ended up stuck on 'breeze', a theme
      # that isn't even installed. Locks always win; plain defaults don't.
      environment.etc."dconf/db/local.d/locks/00-desktop-interface".text = ''
        /org/gnome/desktop/interface/cursor-theme
        /org/gnome/desktop/interface/cursor-size
        /org/gnome/desktop/interface/icon-theme
        /org/gnome/desktop/interface/gtk-theme
      '';

      system.activationScripts.dconfDefaults = ''
        ${pkgs.dconf}/bin/dconf update
      '';
    };
}
