{ ... }: {
  flake.homeManagerModules.git = { ... }: {
    programs.git = {
      enable = true;
      # Not guessed — fill these in yourself, getting commit identity wrong
      # silently is worse than leaving it obviously unset.
      userName = "REPLACE_ME";
      userEmail = "REPLACE_ME";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
      aliases = {
        st = "status -sb";
        co = "checkout";
        lg = "log --oneline --graph --decorate --all";
      };
    };
  };
}
