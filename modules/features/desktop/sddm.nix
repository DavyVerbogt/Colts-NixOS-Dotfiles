{ config, lib, ... }: {

  # SDDM (Wayland) + boot-time random theme pick, now sourced from the
  # active theme's sddmThemes pool (theming/core.nix + theming/themes/*.nix)
  # instead of one hardcoded list. The themes themselves are installed by
  # qylock's NixOS module (see desktop/qylock.nix) — valid names are the
  # directory names under its themes/.
  flake.nixosModules.sddm =
    { ... }:
    let
      pool = config.theme.current.sddmThemes;
    in
    {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };

      # Oneshot re-rolls the greeter theme on every boot. Gated on a
      # non-empty pool: a theme with sddmThemes = [ ] gets no randomizer,
      # and we remove any stale random-theme.conf so programs.qylock's own
      # baseline (services.displayManager.sddm.theme = qylockTheme) wins.
      systemd.services.sddm-random-theme = {
        before = [ "display-manager.service" ];
        wantedBy = [ "display-manager.service" ];
        serviceConfig.Type = "oneshot";
        script =
          if pool == [ ] then ''
            rm -f /etc/sddm.conf.d/random-theme.conf
          '' else ''
            themes=(${lib.concatStringsSep " " (map lib.escapeShellArg pool)})
            selected=''${themes[$RANDOM % ''${#themes[@]}]}
            mkdir -p /etc/sddm.conf.d
            printf '[Theme]\nCurrent=%s\n' "$selected" > /etc/sddm.conf.d/random-theme.conf
          '';
      };
    };
}
