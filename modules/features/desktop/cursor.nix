{ config, lib, ... }: {

  options.desktop = {
    cursorTheme = lib.mkOption {
      type = lib.types.str;
      default = "Banana";
      description = "XCursor theme name.";
    };
    cursorSize = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "XCursor size.";
    };
  };

  config.flake.nixosModules.cursor =
    { pkgs, lib, ... }:
    let
      inherit (config.desktop) cursorTheme cursorSize;
    in
    {
      environment.systemPackages = [ pkgs.banana-cursor ];

      # XCURSOR_THEME/SIZE are unconditional (not just Nvidia-gated) — every
      # client that resolves cursors via libXcursor/libwayland-cursor needs
      # these, not just the compositor itself.
      environment.sessionVariables = {
        XCURSOR_THEME = cursorTheme;
        XCURSOR_SIZE = toString cursorSize;
        XCURSOR_PATH = lib.concatStringsSep ":" [
          "${pkgs.banana-cursor}/share/icons"
          "/run/current-system/sw/share/icons"
          "/etc/profiles/per-user/colt/share/icons"
        ];
      };

      # System-wide cursor default — covers Qt and anything that reads
      # /etc/icons/default/index.theme instead of XCURSOR_THEME directly.
      environment.etc."icons/default/index.theme".text = ''
        [Icon Theme]
        Name=Default
        Comment=Default Cursor Theme
        Inherits=${cursorTheme}
      '';
    };
}
