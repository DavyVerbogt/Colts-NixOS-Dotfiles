# modules/features/desktop/font-rendering.nix
{ ... }: {
  flake.nixosModules.fonts = { pkgs, ... }: {
    fonts = {
      enableDefaultPackages = true; # baseline DejaVu/Liberation/Noto so nothing is glyphless
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        dejavu_fonts
      ];
      fontconfig = {
        enable = true;
        defaultFonts = {
          sansSerif = [
            "Noto Sans"
            "DejaVu Sans"
          ];
          serif = [
            "Noto Serif"
            "DejaVu Serif"
          ];
          monospace = [
            "Liberation Mono"
            "DejaVu Sans Mono"
          ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
  };
}
