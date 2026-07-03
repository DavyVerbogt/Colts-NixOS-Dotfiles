{ lib, ... }: {
  options.desktop.gtkTheme = lib.mkOption {
    type = lib.types.str;
    default = "Sweet-Dark";
    description = "GTK theme name (must match a variant provided by pkgs.sweet).";
  };

  config.flake.nixosModules.gtkTheme = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      sweet # GTK2/3/4 theme — provides Sweet and Sweet-Dark variants
      adw-gtk3 # Noctalia unconditionally references this; must be present
    ];
  };
}
