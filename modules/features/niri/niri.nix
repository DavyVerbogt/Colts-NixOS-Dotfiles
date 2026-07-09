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
      cyberpunk = config.theme.profile == "cyberpunk";

      # Fill these in from `niri msg windows` on ws01-nix — app-ids that
      # should stay fully opaque (opacity 1.0) despite the global 0.90
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
            gaps = 8;

            focus-ring = {
              width = 2;
              active-gradient = _: {
                props = {
                  # Sourced from theme.palette (theming/profiles/*.nix)
                  # instead of hardcoded, with the original hex as fallback.
                  from = config.theme.palette.accent or "#ff0080";
                  to = config.theme.palette.accent2 or "#bf00ff";
                  angle = 45;
                  relative-to = "workspace-view";
                };
              };
              inactive-color = "#2a2a2a";
            };
          };

          # Gated behind theme.profile so minimal/productivity get niri's
          # plain default animations instead of the cyberpunk glitch shader.
          # lib.optionalAttrs (not lib.mkIf!) because this whole `settings`
          # tree is plain data handed to wrapper-modules, not NixOS module
          # config — lib.mkIf's marker value would leak through unresolved.
          animations = lib.optionalAttrs cyberpunk {
            window-open = {
              duration-ms = 500;
              curve = "linear";
              custom-shader = ''
                float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

                vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                    if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) return vec4(0.0);
                    float progress = niri_clamped_progress;
                    float glitch = 1.0 - progress;
                    vec2 uv = coords_geo.xy;

                    float glitch_bar = step(0.90, hash(vec2(floor(uv.y * 20.0), niri_random_seed)));
                    float h_offset = glitch_bar * glitch * 0.15 * (hash(vec2(uv.y, niri_random_seed)) - 0.5);
                    uv.x += h_offset;

                    float split = glitch * 0.12;
                    vec3 cr = niri_geo_to_tex * vec3(uv + vec2(split * 1.5, split * 0.3), 1.0);
                    vec3 cg = niri_geo_to_tex * vec3(uv, 1.0);
                    vec3 cb = niri_geo_to_tex * vec3(uv - vec2(split, -split * 0.2), 1.0);

                    float r = texture2D(niri_tex, cr.st).r;
                    float g = texture2D(niri_tex, cg.st).g;
                    float b = texture2D(niri_tex, cb.st).b;
                    float a = texture2D(niri_tex, cg.st).a;
                    vec3 color = vec3(r, g, b);

                    float noise = hash(uv * 500.0 + niri_random_seed) * glitch * 0.30;
                    color += noise;

                    vec3 cyberpunk_tint = vec3(1.0, 0.2, 0.4);
                    color = mix(color, color * cyberpunk_tint, glitch * 0.4);
                    color.r *= 1.0 + glitch * 0.3;

                    float scanline = 1.0 - 0.12 + 0.12 * sin(uv.y * 450.0);
                    color *= scanline;

                    float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
                    float glow = smoothstep(0.0, 0.15, edge);
                    vec3 neon_red = vec3(1.0, 0.1, 0.3);
                    color += neon_red * (1.0 - glow) * glitch * 1.0;

                    return vec4(color, a * progress);
                }
              '';
            };
            window-close = {
              duration-ms = 700;
              curve = "linear";
              custom-shader = ''
                float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

                vec4 close_color(vec3 coords_geo, vec3 size_geo) {
                    if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) return vec4(0.0);
                    float progress = niri_clamped_progress;
                    vec2 uv = coords_geo.xy;

                    float glitch_bar = step(0.85 - progress * 0.1, hash(vec2(floor(uv.y * 25.0), niri_random_seed + progress)));
                    float h_offset = glitch_bar * progress * 0.20 * (hash(vec2(uv.y, niri_random_seed)) - 0.5);
                    uv.x += h_offset;

                    float tear = step(0.97, hash(vec2(floor(uv.x * 40.0), niri_random_seed)));
                    uv.y += tear * progress * 0.08 * (hash(vec2(uv.x, niri_random_seed)) - 0.5);

                    float split = progress * 0.15;
                    vec3 cr = niri_geo_to_tex * vec3(uv + vec2(split * 1.5, split * 0.4), 1.0);
                    vec3 cg = niri_geo_to_tex * vec3(uv + vec2(0.0, progress * 0.02), 1.0);
                    vec3 cb = niri_geo_to_tex * vec3(uv - vec2(split, -split * 0.3), 1.0);

                    float r = texture2D(niri_tex, cr.st).r;
                    float g = texture2D(niri_tex, cg.st).g;
                    float b = texture2D(niri_tex, cb.st).b;
                    float a = texture2D(niri_tex, cg.st).a;
                    vec3 color = vec3(r, g, b);

                    float noise = hash(uv * 600.0 + niri_random_seed + progress * 10.0) * progress * 0.40;
                    color += noise;

                    vec3 cyberpunk_tint = vec3(1.0, 0.15, 0.35);
                    color = mix(color, color * cyberpunk_tint, progress * 0.5);
                    color.r *= 1.0 + progress * 0.5;
                    color.g *= 1.0 - progress * 0.3;
                    color.b *= 1.0 - progress * 0.2;

                    float scanline = 1.0 - (0.08 + progress * 0.1) + (0.08 + progress * 0.1) * sin(uv.y * 500.0);
                    color *= scanline;

                    float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
                    float glow = smoothstep(0.0, 0.08, edge);
                    vec3 neon_red = vec3(1.0, 0.05, 0.25);
                    color += neon_red * (1.0 - glow) * progress * 1.2;

                    float hot_pixel = step(0.990, hash(uv * 300.0 + progress * 5.0));
                    color += vec3(1.0, 0.3, 0.5) * hot_pixel * progress;

                    return vec4(color, a * (1.0 - progress));
                }
              '';
            };
          };

          window-rules = [
            {
              geometry-corner-radius = 12;
              clip-to-geometry = true;
              opacity = 0.90;
            }
            {
              matches = [
                { title = "^Picture-in-Picture$"; }
              ];
              open-floating = true;
              opacity = 1.0;
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
          ++ lib.optional (opaqueAppIds != [ ]) {
            matches = map (id: { app-id = id; }) opaqueAppIds;
            opacity = 1.0;
          }
          ++ [
            {
              background-effect.blur = true;
              draw-border-with-background = false;
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
