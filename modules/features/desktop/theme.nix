{ lib, ... }: {
  flake.nixosModules.gtkTheme = { pkgs, ... }: {
    # GTK color theme. Owns only the theme package + the option that names it;
    # actual settings.ini rendering lives in desktop/gtk-settings.nix, which
    # reads this option (along with iconTheme/cursorTheme) via closure over
    # the top-level config.
    options.desktop.gtkTheme = lib.mkOption {
      type = lib.types.str;
      default = "Sweet-Dark";
      description = "GTK theme name (must match a variant provided by pkgs.sweet).";
    };

    environment.systemPackages = with pkgs; [
      sweet # GTK2/3/4 theme — provides Sweet and Sweet-Dark variants
      adw-gtk3 # Noctalia unconditionally references this; must be present
    ];
  };
}
