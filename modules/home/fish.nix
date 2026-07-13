{ ... }: {
  flake.homeManagerModules.fish = { pkgs, ... }: {
    programs.fish = {
      enable = true;
      shellAliases = {
        rebuild = "sudo nixos-rebuild switch --flake ~/Documents/NixOS#ws01-nix";
        update = "nix flake update --flake ~/Documents/NixOS";
        gc = "sudo nix-collect-garbage -d";
        ls = "eza --icons";
        cat = "bat";
      };
      interactiveShellInit = ''
        set -g fish_greeting
        zoxide init fish | source
        fzf --fish | source
      '';
      # zoxide is `z`'s actively-maintained successor — rupa/z itself isn't
      # packaged in nixpkgs at all, so this isn't a substitution of taste.
      plugins = [
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
      ];
    };

    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      settings.add_newline = false;
    };

    home.packages = [ pkgs.zoxide ];
    home.stateVersion = "26.05"; # matches system.stateVersion in hosts/ws01-nix/config.nix
  };
}
