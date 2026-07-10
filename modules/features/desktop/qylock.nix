{ inputs, config, ... }: {

  # qylock: Quickshell lock screen + the SDDM theme pack (its NixOS module
  # installs all themes/ dirs into the greeter's theme path — that's where
  # sddm.nix's random pool names resolve). The lock-screen theme is now the
  # active theme's qylockTheme (theming/core.nix + theming/themes/*.nix)
  # instead of a hardcoded "nier-automata".
  flake.nixosModules.qylock =
    { ... }:
    {
      imports = [ inputs.qylock.nixosModules.default ];

      programs.qylock = {
        enable = true;
        theme = config.theme.current.qylockTheme;
      };
    };
}
