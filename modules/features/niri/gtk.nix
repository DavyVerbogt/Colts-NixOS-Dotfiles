{ ... }: {

  # GTK theming feature: Sweet theme, candy-icons, cursor defaults, and the
  # XDG portal needed for gsettings-based dark/light switching on Wayland.
  flake.nixosModules.gtk = { pkgs, ... }: {
    environment.sessionVariables = {
      XCURSOR_THEME = "Banana";
      XCURSOR_SIZE = "24";
    };
    # Generates icon cache files for all installed icon themes.
    # Without this candy-icons won't be found by GTK apps or Thunar.
    gtk.iconCache.enable = true;

    # xdg-desktop-portal-gtk must be running for GTK apps on Wayland to
    # read org.gnome.desktop.interface via gsettings. Without it the
    # Noctalia hook fires but nothing visually changes.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Access" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };

    # gtk.nix owns all GTK settings.ini files — both theme and cursor —
    # to avoid conflicts with niri.nix defining the same etc paths.
    environment.etc."xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name=Sweet-Dark
      gtk-icon-theme-name=candy-icons
      gtk-cursor-theme-name=Banana
      gtk-cursor-theme-size=24
      gtk-application-prefer-dark-theme=1
    '';

    environment.etc."xdg/gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name=Sweet-Dark
      gtk-icon-theme-name=candy-icons
      gtk-cursor-theme-name=Banana
      gtk-cursor-theme-size=24
      gtk-application-prefer-dark-theme=1
    '';

    # System-wide cursor default — covers Qt and anything that reads
    # /etc/icons/default/index.theme (moved here from niri.nix).
    environment.etc."icons/default/index.theme".text = ''
      [Icon Theme]
      Name=Default
      Comment=Default Cursor Theme
      Inherits=Banana
    '';

    environment.systemPackages = with pkgs; [
      sweet # GTK2/3/4 theme — provides Sweet and Sweet-Dark variants
      candy-icons # matching icon theme by the same author (EliverLara)
      adw-gtk3 # Noctalia unconditionally references this; must be present
    ];
  };
}
