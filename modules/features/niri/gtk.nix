{ ... }: {

  # GTK theming feature: Sweet theme with system-wide defaults and the
  # XDG portal needed for gsettings-based dark/light switching on Wayland.
  # Noctalia's darkModeChange hook calls gsettings to swap between Sweet
  # and Sweet-Dark at runtime; this file provides the packages and fallback.
  flake.nixosModules.gtk = { pkgs, ... }: {

    # xdg-desktop-portal-gtk must be running for GTK apps on Wayland to
    # read org.gnome.desktop.interface via gsettings. Without it the
    # Noctalia hook fires but nothing visually changes.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # System-wide fallback — used on first login before Noctalia has fired
    # any hooks. At runtime gsettings takes precedence over this file.
    environment.etc."gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name=Sweet-Dark
      gtk-icon-theme-name=candy-icons
      gtk-cursor-theme-name=Banana
      gtk-cursor-theme-size=24
      gtk-application-prefer-dark-theme=1
    '';

    environment.systemPackages = with pkgs; [
      sweet      # GTK2/3/4 theme — provides Sweet and Sweet-Dark variants
      candy-icons # matching icon theme by the same author (EliverLara)
      adw-gtk3   # Noctalia unconditionally references this; must be present
    ];
  };
}
