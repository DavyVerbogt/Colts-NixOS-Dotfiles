{ lib, ... }: {
  # adw-gtk3(-dark) is now the active default, not Sweet(-Dark). Noctalia's
  # GTK color-scheme template drives adw-gtk3's runtime accent colors — Sweet
  # has its own fixed palette baked in and ignores whatever Noctalia
  # generates, so syncing had no visible effect while Sweet-Dark was active.
  # pkgs.sweet stays installed below if you ever want to switch back manually.
  options.desktop.gtkTheme = lib.mkOption {
    type = lib.types.str;
    default = "adw-gtk3-dark";
    description = "GTK theme name (adw-gtk3/adw-gtk3-dark for Noctalia color sync, or a Sweet variant).";
  };

  config.flake.nixosModules.gtkTheme = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      sweet # GTK2/3/4 theme — provides Sweet and Sweet-Dark variants (manual fallback)
      adw-gtk3 # active theme; Noctalia's color template targets this
    ];
  };
}
