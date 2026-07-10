{ inputs, config, ... }: {

  flake.nixosModules.spicetify =
    { pkgs, lib, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      ohitstom = pkgs.fetchFromGitHub {
        owner = "ohitstom";
        repo = "spicetify-extensions";
        rev = "main";
        hash = "sha256-1fPCUcaTTmxGWmiPfq6mJDzMJ85IK1RovMOfCp2Jfew=";
      };
    in
    {
      imports = [ inputs.spicetify-nix.nixosModules.default ];

      programs.spicetify = {
        enable = true;
        # "text" theme (was comfy), with its color scheme driven by the
        # active theme's spicetifyColorScheme (theming/themes/*.nix) —
        # TokyoNight/Gruvbox/Nord for cyberpunk/minimal/productivity.
        # Valid names = the [sections] of the text theme's color.ini.
        theme = spicePkgs.themes.text;
        colorScheme = lib.mkIf (config.theme.current.spicetifyColorScheme != "")
          config.theme.current.spicetifyColorScheme;

        enabledExtensions = with spicePkgs.extensions; [
          adblock
          shuffle
          volumePercentage
          popupLyrics
          skipStats
          wikify
          betterGenres
          history
          autoVolume
          aiBandBlocker
          romajiConvert
          sortPlay
          {
            src = ohitstom + /scannables;
            name = "scannables.js";
          }
          {
            src = ohitstom + /noControls;
            name = "noControls.js";
          }
          #{
          #src = ohitstom + /pixelatedImages;
          #name = "pixelatedImages.js";
          #}
        ];
      };
    };
}
