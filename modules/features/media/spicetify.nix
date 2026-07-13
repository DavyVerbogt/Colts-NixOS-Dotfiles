{ inputs, config, ... }: {

  flake.nixosModules.spicetify =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.spotify ];
    };

  #{ pkgs, lib, ... }:
  #let
  #  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  #  ohitstom = pkgs.fetchFromGitHub {
  #    owner = "ohitstom";
  #    repo = "spicetify-extensions";
  #    rev = "main";
  #    hash = "sha256-1fPCUcaTTmxGWmiPfq6mJDzMJ85IK1RovMOfCp2Jfew=";
  #  };
  #in
  #{
  #  imports = [ inputs.spicetify-nix.nixosModules.default ];
  #
  #  programs.spicetify = {
  #    enable = true;
  #
  #    # Spotify's bundled Chromium can't start a GPU process under native
  #    # Wayland on Nvidia (595.84) — it hangs at the loading spinner. Force
  #    # XWayland, exactly like the working vanilla build. Default (null)
  #    # follows NIXOS_OZONE_WL, which pushes it onto native Wayland here.
  #    wayland = false;
  #
  #    theme = spicePkgs.themes.text;
  #    colorScheme = lib.mkIf (
  #      config.theme.current.spicetifyColorScheme != ""
  #    ) config.theme.current.spicetifyColorScheme;
  #
  #    enabledExtensions = with spicePkgs.extensions; [
  #      shuffle
  #      volumePercentage
  #      popupLyrics
  #      skipStats
  #      wikify
  #      betterGenres
  #      history
  #      autoVolume
  #      aiBandBlocker
  #      romajiConvert
  #      sortPlay
  #      {
  #        src = ohitstom + /scannables;
  #        name = "scannables.js";
  #      }
  #      {
  #        src = ohitstom + /noControls;
  #        name = "noControls.js";
  #      }
  #    ];
  #  };
  #};
}
