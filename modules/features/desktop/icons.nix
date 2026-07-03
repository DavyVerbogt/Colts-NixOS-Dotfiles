{ lib, ... }: {
  flake.nixosModules.iconTheme = { pkgs, ... }: {
    # Icon theme. Owns only the icon package + the option that names it;
    # actual settings.ini rendering lives in desktop/gtk-settings.nix.
    options.desktop.iconTheme = lib.mkOption {
      type = lib.types.str;
      default = "candy-icons";
      description = "GTK icon theme name.";
    };

    environment.systemPackages = [ pkgs.candy-icons ];
  };
}
