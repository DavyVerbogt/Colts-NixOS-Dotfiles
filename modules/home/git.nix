{ ... }: {
  flake.homeManagerModules.git = { ... }: {
    programs.git = {
      enable = true;
      # userName/userEmail/extraConfig/aliases are the old, renamed option
      # names — current Home Manager wants everything under `settings`.
      settings = {
        user = {
          # Not guessed — fill these in yourself, getting commit identity
          # wrong silently is worse than leaving it obviously unset.
          name = "REPLACE_ME";
          email = "REPLACE_ME";
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        alias = {
          st = "status -sb";
          co = "checkout";
          lg = "log --oneline --graph --decorate --all";
        };
      };
    };
  };
}
