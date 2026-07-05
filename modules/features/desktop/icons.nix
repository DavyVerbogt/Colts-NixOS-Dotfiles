{ lib, ... }: {

  options.desktop.iconTheme = lib.mkOption {
    type = lib.types.str;
    default = "candy-icons";
    description = "GTK icon theme name.";
  };

  config.flake.nixosModules.iconTheme = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.candy-icons
      # candy-icons' index.theme declares Inherits=breeze-dark,Adwaita,hicolor.
      # Without these installed, every icon candy-icons doesn't personally
      # ship falls through straight to hicolor's near-empty placeholders —
      # that's the generic-icon symptom.
      pkgs.adwaita-icon-theme
      pkgs.kdePackages.breeze-icons
    ];
  };
}
