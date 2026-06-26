{ self, inputs, ... }: {

  flake.nixosModules.niri =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      programs.niri = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.NiriConf;
      };
      environment = {
        systemPackages = [ pkgs.banana-cursor ];
        sessionVariables = lib.mkIf config.hardware.nvidia.modesetting.enable {
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          LIBVA_DRIVER_NAME = "nvidia";
          __GL_GSYNC_ALLOWED = "1";
          __GL_VRR_ALLOWED = "1";
          XCURSOR_THEME = "Banana";
          XCURSOR_SIZE = "24";
        };
      };
      environment.etc."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-cursor-theme-name=Banana
        gtk-cursor-theme-size=24
      '';

      # GTK4 apps
      environment.etc."gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-cursor-theme-name=Banana
        gtk-cursor-theme-size=24
      '';

      # System-wide default cursor (covers Qt and anything else that checks this)
      environment.etc."icons/default/index.theme".text = ''
        [Icon Theme]
        Name=Default
        Comment=Default Cursor Theme
        Inherits=Banana
      '';
    };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.NiriConf = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        v2-settings = true;
        settings = {
          spawn-at-startup = [
            (lib.getExe self'.packages.NoctaliaConf)
          ];

          prefer-no-csd = true;

          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          input.keyboard.xkb.layout = "us,ua";

          layout = {
            gaps = 8;

            focus-ring = {
              width = 2;
              active-gradient = _: {
                props = {
                  from = "#ff0080";
                  to = "#bf00ff";
                  angle = 45;
                  relative-to = "workspace-view";
                };
              };
              inactive-color = "#2a2a2a";
            };
          };

          window-rules = [
            {
              geometry-corner-radius = 12;
              clip-to-geometry = true;
              opacity = 0.90;
            }
            {
              background-effect.blur = true;
              draw-border-with-background = false;
            }
          ];

          binds = {
            "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
            "Mod+Q".close-window = { };
            "Mod+Space".spawn-sh = "${lib.getExe self'.packages.NoctaliaConf} ipc call launcher toggle";

            # Media control
            "XF86AudioPlay".spawn-sh = "${lib.getExe pkgs.playerctl} play-pause";
            "XF86AudioNext".spawn-sh = "${lib.getExe pkgs.playerctl} next";
            "XF86AudioPrev".spawn-sh = "${lib.getExe pkgs.playerctl} previous";

            # Volume control
            "XF86AudioRaiseVolume".spawn-sh =
              "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
            "XF86AudioLowerVolume".spawn-sh =
              "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
            "XF86AudioMute".spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

            "Print".screenshot = { }; # interactive region/screen picker
            "Shift+Print".screenshot-screen = { }; # current screen instantly
            "Alt+Print".screenshot-window = { }; # focused window instantly
          };
          cursor = {
            xcursor-theme = "Banana";
            xcursor-size = 24;
          };
        };
      };
    };

}
