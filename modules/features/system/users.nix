{ ... }: {
  flake.nixosModules.users = { pkgs, ... }: {
    users.users.colt = {
      shell = pkgs.fish;
      isNormalUser = true;
      description = "Colt";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };

    # fish is colt's login shell, so it's enabled alongside the user
    programs.fish.enable = true;
    programs.direnv.enableFishIntegration = true;
  };
}
