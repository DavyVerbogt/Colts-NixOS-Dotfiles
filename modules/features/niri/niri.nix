{
  self,
  inputs,
  config,
  ...
}:
{

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
        systemPackages = [
          pkgs.banana-cursor
          pkgs.hyprpicker
          inputs.niri-session-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
        sessionVariables = lib.mkIf config.hardware.nvidia.modesetting.enable {
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          LIBVA_DRIVER_NAME = "nvidia";
          __GL_GSYNC_ALLOWED = "1";
          __GL_VRR_ALLOWED = "1";
        };
      };
      # gtk-3.0/settings.ini, gtk-4.0/settings.ini, and icons/default/index.theme
      # are all owned by desktop/gtk-settings.nix and desktop/cursor.nix to
      # avoid module conflicts.
    };
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    let
      # All visual knobs come from the active theme (theming/core.nix +
      # theming/themes/*.nix): gaps, corner radius, opacity, inactive
      # border color, and which open/close shader is active.
      th = config.theme.current;

      # The theme names a shader; the actual animation snippets live in
      # the niri.shaders registry (shaders.nix, sourced from the
      # nirimation collection). "none" maps to an empty attrset there —
      # same result as the old glitchShader = false (settings.animations
      # ended up {} via optionalAttrs), so niri keeps stock animations.
      # `config` here is the top-level flake-parts config (perSystem's
      # own args don't shadow it), same trick th relies on.
      shaderAnimations =
        config.niri.shaders.${th.niri.shader} or (throw ''
          theme "${config.theme.active}" sets niri.shader = "${th.niri.shader}" but the
          niri.shaders registry has no such entry (have: ${lib.concatStringsSep ", " (lib.attrNames config.niri.shaders)})'');

      # Fill these in from `niri msg windows` on ws01-nix — app-ids that
      # should stay fully opaque (opacity 1.0) despite the global opacity
      # below. Empty list = no exclusions, i.e. today's behavior.
      opaqueAppIds = [
        # "^steam$"
        # "^org\\.prismlauncher\\.PrismLauncher$"
      ];
    in
    {
      packages.NiriConf = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        v2-settings = true;
        settings = {
          spawn-at-startup = [
            (lib.getExe self'.packages.NoctaliaConf)
            "${
              inputs.niri-session-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
            }/bin/niri-session-manager"
          ];

          prefer-no-csd = true;

          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          input = {
            keyboard.xkb.layout = "us,ua";
            # Per-device tuning from desktop/input.nix — flat/precise for
            # ws01-nix's real mouse today; a laptop host would read
            # "adaptive" here automatically via device.class.
            mouse = {
              accel-profile = config.desktop.mouse.accelProfile;
              accel-speed = config.desktop.mouse.accelSpeed;
            };
          };

          layout = {
            gaps = th.niri.gaps;

            focus-ring = {
              width = 2;
              active-gradient = _: {
                props = {
                  # Sourced from theme.palette (theming/themes/*.nix)
                  # instead of hardcoded, with the original hex as fallback.
                  from = config.theme.palette.accent or "#ff0080";
                  to = config.theme.palette.accent2 or "#bf00ff";
                  angle = 45;
                  relative-to = "workspace-view";
                };
              };
              inactive-color = th.niri.inactiveColor;
            };
          };

          # Which shader (if any) comes straight from the registry lookup
          # above. Plain data on purpose — this settings tree goes to
          # wrapper-modules, not the NixOS module system, so no mkIf here.
          animations = shaderAnimations;

          # Rule order matters: niri merges matching rules with later ones
          # winning, so the per-app opacity rules (from the theme's
          # niri.appOpacity) come after the global default, and the manual
          # opaqueAppIds escape hatch stays last.
          window-rules = [
            {
              geometry-corner-radius = th.niri.cornerRadius;
              clip-to-geometry = true;
              opacity = th.niri.windowOpacity;
            }
            {
              matches = [
                { title = "^Picture-in-Picture$"; }
              ];
              open-floating = true;
              # opacity + blur for PiP live in the dedicated rule appended
              # AFTER the blur-all rule below — later rules win, so setting
              # them here would just get overridden.
              default-floating-position = _: {
                props = {
                  x = 32;
                  y = 32;
                  relative-to = "bottom-right";
                };
              };
              default-column-width = {
                fixed = 480;
              };
              default-window-height = {
                fixed = 270;
              };
            }
          ]
          ++ lib.mapAttrsToList (regex: op: {
            matches = [ { app-id = regex; } ];
            opacity = op;
          }) th.niri.appOpacity
          ++ lib.optional (opaqueAppIds != [ ]) {
            matches = map (id: { app-id = id; }) opaqueAppIds;
            opacity = 1.0;
          }
          ++ [
            {
              background-effect.blur = true;
              draw-border-with-background = false;
            }
            # PiP last so it beats both the appOpacity rules and the
            # blur-all rule above: translucent per the theme's pipOpacity,
            # and never frosted — you want to see the video, not a blur of
            # whatever's behind it.
            {
              matches = [
                { title = "^Picture-in-Picture$"; }
              ];
              opacity = th.niri.pipOpacity;
              background-effect.blur = false;
            }
          ];

          binds = {
            "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
            "Mod+Q".close-window = { };
            "Mod+Space".spawn-sh = "${lib.getExe self'.packages.NoctaliaConf} ipc call launcher toggle";

            "XF86AudioPlay".spawn-sh = "${lib.getExe pkgs.playerctl} play-pause";
            "XF86AudioNext".spawn-sh = "${lib.getExe pkgs.playerctl} next";
            "XF86AudioPrev".spawn-sh = "${lib.getExe pkgs.playerctl} previous";

            "XF86AudioRaiseVolume".spawn-sh =
              "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
            "XF86AudioLowerVolume".spawn-sh =
              "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
            "XF86AudioMute".spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

            "Print".spawn-sh = lib.getExe self'.packages.ScreenshotFull;
            "Shift+Print".spawn-sh = lib.getExe self'.packages.ScreenshotRegion;
            "Alt+Print".screenshot-window = { };
            "Mod+Shift+C".spawn-sh = "${lib.getExe pkgs.hyprpicker} -a"; # copy hex under cursor to clipboard

            # Navigate between app columns on the horizontal strip
            "Mod+Left".focus-column-left = { };
            "Mod+Right".focus-column-right = { };
            "Mod+XF86Back".focus-column-left = { };
            "Mod+XF86Forward".focus-column-right = { };

            # Switch workspaces with keyboard
            "Mod+Page_Down".focus-workspace-down = { };
            "Mod+Page_Up".focus-workspace-up = { };

            # Switch workspaces by holding Mod and scrolling the mouse wheel
            "Mod+WheelScrollDown".focus-workspace-down = { };
            "Mod+WheelScrollUp".focus-workspace-up = { };

            # Move the focused window to another workspace
            "Mod+Shift+Page_Down".move-window-to-workspace-down = { };
            "Mod+Shift+Page_Up".move-window-to-workspace-up = { };
          };

          # Cursor theme/size now sourced from desktop/cursor.nix's options
          # instead of a second hardcoded "Banana"/24 — keeps the compositor's
          # own cursor rendering in sync with everything else automatically.
          cursor = {
            xcursor-theme = config.desktop.cursorTheme;
            xcursor-size = config.desktop.cursorSize;
          };
        };
      };
    };
}
