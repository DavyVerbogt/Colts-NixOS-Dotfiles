{ self, inputs, ... }: {

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
        theme = spicePkgs.themes.text;

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
