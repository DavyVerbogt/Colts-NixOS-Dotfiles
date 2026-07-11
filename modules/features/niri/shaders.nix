{ lib, ... }:
{
  # ------------------------------------------------------------------
  # Open registry of niri window open/close animation shaders, in the
  # same spirit as theme.themes: a theme picks one by name via its
  # niri.shader option (theming/core.nix), niri.nix merges the chosen
  # entry into settings.animations, and adding your own effect is just
  # another attrset here (or in any other file - it's a plain
  # flake-parts option, so definitions merge).
  #
  # Every entry below is extracted verbatim (GLSL, durations, curves)
  # from the nirimation collection, which is already pinned as a flake
  # input (inputs.nirimation, Xansidev/nirimation @ a5f8f8b, MIT).
  # workspace-switch tweaks from those files are deliberately NOT
  # carried over - this registry only owns open/close/resize effects.
  # Regenerate/compare against "$(nix flake metadata --json | jq -r
  # .locks.nodes.nirimation)" if you ever bump that input.
  #
  # "none" is the explicit no-op: settings.animations gets an empty
  # attrset, exactly what the old glitchShader = false produced, so
  # niri keeps its stock animations.
  # ------------------------------------------------------------------
  options.niri.shaders = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    default = { };
    description = ''
      Named niri animation snippets ({ window-open, window-close, and
      optionally window-resize } in wrapper-modules settings form).
      Themes select one via theme.themes.<name>.niri.shader.
    '';
  };

  config.niri.shaders = {
    none = { };

    "bloom" = {
      "window-open" = {
        duration-ms = 250;
        curve = "linear";
        custom-shader = ''
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
            float p0 = niri_clamped_progress;
            float p  = smoothstep(0.0, 1.0, p0);

            vec2 size   = size_geo.xy;
            vec2 center = size * 0.5;
            vec2 pos    = coords_geo.xy * size;

            float scale = mix(0.01, 1.0, p);

            vec2 scaled_pos = (pos - center) / scale + center;
            vec2 uv = scaled_pos / size;

            if (uv.x < 0.0 || uv.x > 1.0 ||
                uv.y < 0.0 || uv.y > 1.0) {
                return vec4(0.0, 0.0, 0.0, 0.0);
            }

            return texture2D(niri_tex, uv);
          }
        '';
      };
      "window-close" = {
        duration-ms = 250;
        curve = "linear";
        custom-shader = ''
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
            float p0 = niri_clamped_progress;
            float p  = smoothstep(0.0, 1.0, p0);

            vec2 size   = size_geo.xy;
            vec2 center = size * 0.5;
            vec2 pos    = coords_geo.xy * size;

            float scale = mix(1.0, 0.01, p);

            vec2 scaled_pos = (pos - center) / scale + center;
            vec2 uv = scaled_pos / size;

            if (uv.x < 0.0 || uv.x > 1.0 ||
                uv.y < 0.0 || uv.y > 1.0) {
                return vec4(0.0, 0.0, 0.0, 0.0);
            }

            return texture2D(niri_tex, uv);
          }
        '';
      };
    };

    "burn-ashes" = {
      "window-open" = {
        duration-ms = 700;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
          float noise(vec2 p) {
              vec2 i = floor(p); vec2 f = fract(p);
              f = f * f * (3.0 - 2.0 * f);
              return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
                         mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
          }
          vec3 get_ember_colors(float seed, out vec3 inner, out vec3 outer) {
              if (seed < 0.125) { inner = vec3(1.0, 0.3, 0.0); outer = vec3(1.0, 0.8, 0.2); }       // orange
              else if (seed < 0.250) { inner = vec3(0.2, 0.4, 1.0); outer = vec3(0.5, 0.8, 1.0); } // blue
              else if (seed < 0.375) { inner = vec3(0.6, 0.1, 0.9); outer = vec3(0.9, 0.5, 1.0); } // purple
              else if (seed < 0.500) { inner = vec3(0.1, 0.8, 0.2); outer = vec3(0.5, 1.0, 0.3); } // green
              else if (seed < 0.625) { inner = vec3(1.0, 0.1, 0.4); outer = vec3(1.0, 0.5, 0.7); } // pink
              else if (seed < 0.750) { inner = vec3(0.0, 0.8, 0.9); outer = vec3(0.7, 1.0, 1.0); } // cyan
              else if (seed < 0.875) { inner = vec3(0.9, 0.7, 0.1); outer = vec3(1.0, 1.0, 0.8); } // gold
              else { inner = vec3(0.8, 0.2, 0.1); outer = vec3(1.0, 0.5, 0.2); }                   // red
              return inner;
          }
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) return vec4(0.0);
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;
              vec3 coords_tex = niri_geo_to_tex * vec3(uv, 1.0);
              vec4 color = texture2D(niri_tex, coords_tex.st);
              float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
              float n = noise(uv * 8.0 + niri_random_seed * 100.0) * 0.3;
              float burn_line = edge_dist + n;
              float threshold = progress * 0.8;
              vec3 ember_inner, ember_outer;
              get_ember_colors(niri_random_seed, ember_inner, ember_outer);
              if (burn_line < threshold - 0.08) return color;
              else if (burn_line < threshold) {
                  vec3 ember = mix(ember_inner, ember_outer, (burn_line - threshold + 0.08) / 0.08);
                  return vec4(mix(ember, color.rgb, 0.3), color.a);
              } else return vec4(0.0);
          }
        '';
      };
      "window-close" = {
        duration-ms = 700;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
          float noise(vec2 p) {
              vec2 i = floor(p); vec2 f = fract(p);
              f = f * f * (3.0 - 2.0 * f);
              return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
                         mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
          }
          vec3 get_ember_colors(float seed, out vec3 inner, out vec3 outer) {
              if (seed < 0.125) { inner = vec3(1.0, 0.3, 0.0); outer = vec3(1.0, 0.8, 0.2); }
              else if (seed < 0.250) { inner = vec3(0.2, 0.4, 1.0); outer = vec3(0.5, 0.8, 1.0); }
              else if (seed < 0.375) { inner = vec3(0.6, 0.1, 0.9); outer = vec3(0.9, 0.5, 1.0); }
              else if (seed < 0.500) { inner = vec3(0.1, 0.8, 0.2); outer = vec3(0.5, 1.0, 0.3); }
              else if (seed < 0.625) { inner = vec3(1.0, 0.1, 0.4); outer = vec3(1.0, 0.5, 0.7); }
              else if (seed < 0.750) { inner = vec3(0.0, 0.8, 0.9); outer = vec3(0.7, 1.0, 1.0); }
              else if (seed < 0.875) { inner = vec3(0.9, 0.7, 0.1); outer = vec3(1.0, 1.0, 0.8); }
              else { inner = vec3(0.8, 0.2, 0.1); outer = vec3(1.0, 0.5, 0.2); }
              return inner;
          }
          float ash_particle(vec2 uv, float seed) {
              float pn = noise(uv * 150.0 + seed * 50.0);
              return pn < 0.78 ? 0.0 : (pn - 0.78) / 0.22;
          }
          float ember_spark(vec2 uv, float seed) {
              float sn = hash(floor(uv * 280.0) + seed * 100.0);
              return sn < 0.982 ? 0.0 : pow((sn - 0.982) / 0.018, 2.0);
          }
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;
              vec3 ember_inner, ember_outer;
              get_ember_colors(niri_random_seed, ember_inner, ember_outer);
              vec4 particles = vec4(0.0);
              for (float i = 0.0; i < 7.0; i++) {
                  float ls = niri_random_seed + i * 0.1;
                  vec2 auv = uv; auv.y += progress * (0.25 + i * 0.12);
                  auv.x += progress * (noise(vec2(i, ls) * 10.0) - 0.5) * 0.4 + sin(progress * 6.28 + i * 1.5) * 0.03;
                  float ed = min(min(auv.x, 1.0 - auv.x), min(auv.y, 1.0 - auv.y));
                  float sz = progress * 0.75;
                  if (ed < sz && ed > 0.0) {
                      float p = ash_particle(auv, ls);
                      float fade = (1.0 - smoothstep(0.0, sz, ed)) * (1.0 - progress * 0.4);
                      particles.rgb += mix(ember_outer * 0.5, vec3(0.3), 0.4 + i * 0.1) * p * fade * 0.7;
                      particles.a += p * fade * 0.5;
                  }
              }
              for (float j = 0.0; j < 8.0; j++) {
                  float ss = niri_random_seed + j * 0.17 + 0.5;
                  vec2 suv = uv; suv.y += progress * (0.4 + j * 0.1);
                  suv.x += progress * (hash(vec2(j, ss)) - 0.5) * 0.5 + sin(progress * 10.0 + j * 2.0) * 0.025;
                  float ed = min(min(suv.x, 1.0 - suv.x), min(suv.y, 1.0 - suv.y));
                  float sz = progress * 0.7;
                  if (ed < sz && ed > 0.0) {
                      float sp = ember_spark(suv, ss);
                      float fade = (1.0 - smoothstep(0.0, sz * 0.8, ed)) * (1.0 - progress * 0.6);
                      float flicker = 0.7 + 0.3 * sin(progress * 20.0 + j * 3.0);
                      particles.rgb += ember_inner * sp * fade * flicker * 1.5;
                      particles.a += sp * fade * 0.8;
                  }
              }
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) return particles;
              vec3 coords_tex = niri_geo_to_tex * vec3(uv, 1.0);
              vec4 color = texture2D(niri_tex, coords_tex.st);
              float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
              float n = noise(uv * 8.0 + niri_random_seed * 100.0) * 0.3;
              float burn_line = edge_dist + n;
              float threshold = progress * 0.8;
              if (burn_line > threshold + 0.08) return color + particles;
              else if (burn_line > threshold) {
                  vec3 ember = mix(ember_inner, ember_outer, 1.0 - (burn_line - threshold) / 0.08);
                  return vec4(mix(ember, color.rgb, 0.3), color.a) + particles;
              } else return particles;
          }
        '';
      };
    };

    "burn-multicolor" = {
      "window-open" = {
        duration-ms = 700;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) {
              return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
          }
          float noise(vec2 p) {
              vec2 i = floor(p);
              vec2 f = fract(p);
              f = f * f * (3.0 - 2.0 * f);
              return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
                         mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
          }
          vec3 get_ember_colors(float seed, out vec3 inner, out vec3 outer) {
              if (seed < 0.125) {
                  inner = vec3(1.0, 0.3, 0.0);       // orange
                  outer = vec3(1.0, 0.8, 0.2);
              } else if (seed < 0.25) {
                  inner = vec3(0.2, 0.4, 1.0);       // blue
                  outer = vec3(0.5, 0.8, 1.0);
              } else if (seed < 0.375) {
                  inner = vec3(0.6, 0.1, 0.9);       // purple
                  outer = vec3(0.9, 0.5, 1.0);
              } else if (seed < 0.5) {
                  inner = vec3(0.1, 0.8, 0.2);       // green
                  outer = vec3(0.5, 1.0, 0.3);
              } else if (seed < 0.625) {
                  inner = vec3(1.0, 0.1, 0.4);       // pink
                  outer = vec3(1.0, 0.5, 0.7);
              } else if (seed < 0.75) {
                  inner = vec3(0.0, 0.8, 0.9);       // cyan
                  outer = vec3(0.7, 1.0, 1.0);
              } else if (seed < 0.875) {
                  inner = vec3(0.9, 0.7, 0.1);       // gold
                  outer = vec3(1.0, 1.0, 0.8);
              } else {
                  inner = vec3(0.8, 0.2, 0.1);       // deep red
                  outer = vec3(1.0, 0.5, 0.2);
              }
              return inner;
          }
          vec4 burn_open(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) {
                  return vec4(0.0);
              }
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;
              vec3 coords_tex = niri_geo_to_tex * vec3(uv, 1.0);
              vec4 color = texture2D(niri_tex, coords_tex.st);

              float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
              float n = noise(uv * 9.0 + niri_random_seed * 100.0) * 0.3;
              float burn_line = edge_dist + n;
              float threshold = progress * 0.8;

              vec3 ember_inner, ember_outer;
              get_ember_colors(niri_random_seed, ember_inner, ember_outer);

              if (burn_line < threshold - 0.08) {
                  return color;
              } else if (burn_line < threshold) {
                  vec3 ember = mix(ember_inner, ember_outer, (burn_line - threshold + 0.08) / 0.08);
                  return vec4(mix(ember, color.rgb, 0.3), color.a);
              } else {
                  return vec4(0.0);
              }
          }
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              return burn_open(coords_geo, size_geo);
          }
        '';
      };
      "window-close" = {
        duration-ms = 1200;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) {
              return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
          }
          float noise(vec2 p) {
              vec2 i = floor(p);
              vec2 f = fract(p);
              f = f * f * (3.0 - 2.0 * f);
              return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
                         mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
          }
          vec3 get_ember_colors(float seed, out vec3 inner, out vec3 outer) {
              if (seed < 0.125) {
                  inner = vec3(1.0, 0.3, 0.0);       // orange
                  outer = vec3(1.0, 0.8, 0.2);
              } else if (seed < 0.25) {
                  inner = vec3(0.2, 0.4, 1.0);       // blue
                  outer = vec3(0.5, 0.8, 1.0);
              } else if (seed < 0.375) {
                  inner = vec3(0.6, 0.1, 0.9);       // purple
                  outer = vec3(0.9, 0.5, 1.0);
              } else if (seed < 0.5) {
                  inner = vec3(0.1, 0.8, 0.2);       // green
                  outer = vec3(0.5, 1.0, 0.3);
              } else if (seed < 0.625) {
                  inner = vec3(1.0, 0.1, 0.4);       // pink
                  outer = vec3(1.0, 0.5, 0.7);
              } else if (seed < 0.75) {
                  inner = vec3(0.0, 0.8, 0.9);       // cyan
                  outer = vec3(0.7, 1.0, 1.0);
              } else if (seed < 0.875) {
                  inner = vec3(0.9, 0.7, 0.1);       // gold
                  outer = vec3(1.0, 1.0, 0.8);
              } else {
                  inner = vec3(0.8, 0.2, 0.1);       // deep red
                  outer = vec3(1.0, 0.5, 0.2);
              }
              return inner;
          }
          vec4 burn_close(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) {
                  return vec4(0.0);
              }
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;
              vec3 coords_tex = niri_geo_to_tex * vec3(uv, 1.0);
              vec4 color = texture2D(niri_tex, coords_tex.st);

              float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
              float n = noise(uv * 9.0 + niri_random_seed * 100.0) * 0.3;
              float burn_line = edge_dist + n;
              float threshold = progress * 0.8;

              vec3 ember_inner, ember_outer;
              get_ember_colors(niri_random_seed, ember_inner, ember_outer);

              if (burn_line > threshold + 0.08) {
                  return color;
              } else if (burn_line > threshold) {
                  vec3 ember = mix(ember_inner, ember_outer, 1.0 - (burn_line - threshold) / 0.08);
                  return vec4(mix(ember, color.rgb, 0.3), color.a);
              } else {
                  return vec4(0.0);
              }
          }
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              return burn_close(coords_geo, size_geo);
          }
        '';
      };
    };

    "burn" = {
      "window-open" = {
        duration-ms = 700;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) {
              return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
          }
          float noise(vec2 p) {
              vec2 i = floor(p);
              vec2 f = fract(p);
              f = f * f * (3.0 - 2.0 * f);
              return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
                         mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
          }
          vec4 burn_open(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) {
                  return vec4(0.0);
              }
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;
              vec3 coords_tex = niri_geo_to_tex * vec3(uv, 1.0);
              vec4 color = texture2D(niri_tex, coords_tex.st);

              float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
              float n = noise(uv * 8.0 + niri_random_seed * 100.0) * 0.3;
              float burn_line = edge_dist + n;
              float threshold = progress * 0.8;

              vec3 ember_inner = vec3(1.0, 0.3, 0.0);
              vec3 ember_outer = vec3(1.0, 0.8, 0.2);

              if (burn_line < threshold - 0.08) {
                  return color;
              } else if (burn_line < threshold) {
                  vec3 ember = mix(ember_inner, ember_outer, (burn_line - threshold + 0.08) / 0.08);
                  return vec4(mix(ember, color.rgb, 0.3), color.a);
              } else {
                  return vec4(0.0);
              }
          }
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              return burn_open(coords_geo, size_geo);
          }
        '';
      };
      "window-close" = {
        duration-ms = 1200;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) {
              return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
          }
          float noise(vec2 p) {
              vec2 i = floor(p);
              vec2 f = fract(p);
              f = f * f * (3.0 - 2.0 * f);
              return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
                         mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
          }
          vec4 burn_close(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) {
                  return vec4(0.0);
              }
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;
              vec3 coords_tex = niri_geo_to_tex * vec3(uv, 1.0);
              vec4 color = texture2D(niri_tex, coords_tex.st);

              float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
              float n = noise(uv * 8.0 + niri_random_seed * 100.0) * 0.3;
              float burn_line = edge_dist + n;
              float threshold = progress * 0.8;

              vec3 ember_inner = vec3(1.0, 0.3, 0.0);
              vec3 ember_outer = vec3(1.0, 0.8, 0.2);

              if (burn_line > threshold + 0.08) {
                  return color;
              } else if (burn_line > threshold) {
                  vec3 ember = mix(ember_inner, ember_outer, 1.0 - (burn_line - threshold) / 0.08);
                  return vec4(mix(ember, color.rgb, 0.3), color.a);
              } else {
                  return vec4(0.0);
              }
          }
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              return burn_close(coords_geo, size_geo);
          }
        '';
      };
    };

    "explode" = {
      "window-open" = {
        duration-ms = 550;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
          float noise(vec2 p) {
              vec2 i = floor(p); vec2 f = fract(p);
              f = f * f * (3.0 - 2.0 * f);
              return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
                         mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
          }
          float fbm(vec2 p) {
              float f = 0.0;
              f += 0.5 * noise(p); p *= 2.1;
              f += 0.25 * noise(p); p *= 2.2;
              f += 0.125 * noise(p); p *= 2.3;
              f += 0.0625 * noise(p);
              return f;
          }
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) return vec4(0.0);
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;
              float scale = 0.8 + 0.2 * progress;
              vec2 centered = (uv - 0.5) / scale + 0.5;
              if (centered.x < 0.0 || centered.x > 1.0 || centered.y < 0.0 || centered.y > 1.0) return vec4(0.0);
              vec3 coords_tex = niri_geo_to_tex * vec3(centered, 1.0);
              vec4 color = texture2D(niri_tex, coords_tex.st);
              return vec4(color.rgb, color.a * progress);
          }
        '';
      };
      "window-close" = {
        duration-ms = 550;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
          float noise(vec2 p) {
              vec2 i = floor(p); vec2 f = fract(p);
              f = f * f * (3.0 - 2.0 * f);
              return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
                         mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
          }
          float fbm(vec2 p) {
              float f = 0.0;
              f += 0.5 * noise(p); p *= 2.1;
              f += 0.25 * noise(p); p *= 2.2;
              f += 0.125 * noise(p); p *= 2.3;
              f += 0.0625 * noise(p);
              return f;
          }
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;
              vec2 center = vec2(0.5, 0.5);
              vec2 dir = uv - center;
              float dist = length(dir);
              float angle = atan(dir.y, dir.x);

              // Quick expansion
              float expand = pow(progress, 0.5) * 1.5;

              // ASYMMETRIC SHAPE - varying lobes and angles
              float lobe1 = 0.3 * sin(angle * 2.0 + niri_random_seed * 6.28);
              float lobe2 = 0.2 * sin(angle * 3.0 + niri_random_seed * 3.14 + 1.0);
              float lobe3 = 0.15 * sin(angle * 5.0 + niri_random_seed * 4.0);
              float asymmetry = 1.0 + lobe1 + lobe2 + lobe3;

              // Noise on top
              float turb = fbm(vec2(angle * 2.0 + niri_random_seed * 10.0, progress * 3.0)) * 0.35;
              float fire_edge = expand * asymmetry * (0.75 + turb);

              // Colors - classic C&C palette
              vec3 white_hot = vec3(1.0, 1.0, 0.85);
              vec3 yellow = vec3(1.0, 0.85, 0.2);
              vec3 orange = vec3(1.0, 0.55, 0.1);
              vec3 dark_orange = vec3(0.85, 0.35, 0.05);
              vec3 red_brown = vec3(0.5, 0.15, 0.05);
              vec3 grey_smoke = vec3(0.65, 0.62, 0.58);

              // Fire layers with chunkyness
              float fire_turb = fbm((uv - center) * 8.0 - progress * 3.0 + niri_random_seed * 5.0);
              float fire_turb2 = fbm((uv - center) * 12.0 + progress * 2.0 + niri_random_seed * 8.0);

              // Asymmetric core of animation, off-centered
              vec2 core_offset = vec2(
                  0.03 * sin(niri_random_seed * 5.0),
                  0.03 * cos(niri_random_seed * 7.0)
              );
              float core_dist = length(uv - center - core_offset);

              // Core glow
              float core = smoothstep(fire_edge * 0.3, 0.0, core_dist);
              // Inner yellow
              float inner = smoothstep(fire_edge * 0.45, fire_edge * 0.15, dist);
              // Orange body
              float mid = smoothstep(fire_edge * 0.7, fire_edge * 0.3, dist);
              // Outer burn
              float outer = smoothstep(fire_edge, fire_edge * 0.5, dist);

              // Dark patches in fire (for the chunky look)
              float dark_patches = fire_turb * fire_turb2;
              dark_patches = smoothstep(0.12, 0.35, dark_patches) * mid * (1.0 - core);

              // Fire color
              vec3 fire = red_brown;
              fire = mix(fire, dark_orange, outer);
              fire = mix(fire, orange, mid * (1.0 - dark_patches * 0.7));
              fire = mix(fire, yellow, inner);
              fire = mix(fire, white_hot, core);

              // Add dark turbulent patches
              fire = mix(fire, red_brown, dark_patches * 0.65);

              // Smoke ring - also asymmetric
              float smoke_edge = fire_edge * (1.0 + 0.2 * sin(angle * 4.0 + niri_random_seed));
              float smoke_ring = smoothstep(smoke_edge * 0.8, smoke_edge * 1.2, dist);
              smoke_ring *= smoothstep(smoke_edge * 1.7, smoke_edge * 1.1, dist);
              float smoke_turb = fbm((uv - center) * 4.0 + niri_random_seed * 3.0);
              smoke_ring *= (0.4 + smoke_turb * 0.6) * 0.6;

              // Debris particles
              float debris = 0.0;
              for (float i = 0.0; i < 30.0; i++) {
                  float a = hash(vec2(i, niri_random_seed)) * 6.28;
                  float spd = 0.3 + hash(vec2(i * 2.0, niri_random_seed)) * 0.7;
                  float dly = hash(vec2(i * 3.0, niri_random_seed)) * 0.15;
                  float t = clamp((progress - dly) / (1.0 - dly), 0.0, 1.0);
                  vec2 pos = center + vec2(cos(a), sin(a)) * t * spd * expand;
                  float d = length(uv - pos);
                  float size = 0.006 + hash(vec2(i * 4.0, niri_random_seed)) * 0.01;
                  debris += smoothstep(size, 0.0, d) * (1.0 - t * t);
              }

              // Timing - quick flash, sustain, fades out completely
              float flash = smoothstep(0.0, 0.12, progress);
              float fadeout = pow(smoothstep(1.0, 0.2, progress), 2.0);

              // Fade to nothing
              float fire_a = max(max(core, inner), max(mid, outer)) * flash * fadeout;

              // Combine
              vec3 result = fire;
              result = mix(result, grey_smoke, smoke_ring * fadeout);
              result += vec3(1.0, 0.7, 0.2) * debris * fadeout;

              // Window gone immediately (couldn't figure this out for a while)
              vec3 coords_tex = niri_geo_to_tex * vec3(uv, 1.0);
              vec4 win = vec4(0.0);
              if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
                  win = texture2D(niri_tex, coords_tex.st);
              }
              float win_fade = 1.0 - smoothstep(0.0, 0.03, progress);
              win.a *= win_fade;

              // Everything fades out by end
              float explosion_a = max(fire_a, smoke_ring * fadeout * 0.7);
              float total_a = max(win.a, explosion_a);
              float blend = clamp(fire_a + smoke_ring * 0.4 + smoothstep(0.0, 0.05, progress), 0.0, 1.0);
              vec3 final_color = mix(win.rgb, result, blend);

              return vec4(final_color, total_a * fadeout);
          }
        '';
      };
    };

    "fold-window" = {
      "window-open" = {
        duration-ms = 900;
        curve = "ease-out-expo";
        custom-shader = ''
          vec4 door_rise(vec3 coords_geo, vec3 size_geo) {
              float progress = niri_clamped_progress;

              // Tilt from 90 degrees (flat) to 0 degrees (upright)
              float tilt = (1.0 - progress) * 1.57079632;

              // Pivot point at bottom edge
              vec2 coords = coords_geo.xy * size_geo.xy;
              coords.y = size_geo.y - coords.y;

              // Distance from pivot (bottom edge)
              float dist_from_pivot = coords.y;

              // Calculate 3D position
              // Negative z_offset so it goes away from viewer (backward)
              float z_offset = -dist_from_pivot * sin(tilt);
              float y_compressed = dist_from_pivot * cos(tilt);

              // Apply perspective based on depth
              float perspective = 600.0;
              float perspective_scale = perspective / (perspective + z_offset);

              // Scale everything by perspective
              coords.x = (coords.x - size_geo.x * 0.5) * perspective_scale + size_geo.x * 0.5;
              coords.y = y_compressed * perspective_scale;

              // Flip Y back to normal coordinates
              coords.y = size_geo.y - coords.y;

              coords_geo = vec3(coords / size_geo.xy, 1.0);

              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 color = texture2D(niri_tex, coords_tex.st);

              // Brighten as it rises
              float brightness = 0.4 + 0.6 * progress;
              color.rgb *= brightness;

              return color * progress;
          }
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              return door_rise(coords_geo, size_geo);
          }
        '';
      };
      "window-close" = {
        duration-ms = 700;
        curve = "ease-out-expo";
        custom-shader = ''
          vec4 bob_and_slide(vec3 coords_geo, vec3 size_geo) {
              float progress = niri_clamped_progress;

              float y_offset = 0.0;

              // Bob phase (0.0 to 0.25) - goes up then back to 0
              if (progress < 0.25) {
                  float t = progress / 0.25;
                  // Parabola: goes up to peak at t=0.5, back down to 0 at t=1.0
                  y_offset = -40.0 * (1.0 - 4.0 * (t - 0.5) * (t - 0.5));
              }
              // Slide phase (0.25 to 1.0) - slides down
              else {
                  float slide_progress = (progress - 0.25) / 0.75;
                  y_offset = -slide_progress * (size_geo.y + 100.0);
              }

              // Apply transformation
              vec2 coords = coords_geo.xy * size_geo.xy;
              coords.y = coords.y + y_offset;

              coords_geo = vec3(coords / size_geo.xy, 1.0);

              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 color = texture2D(niri_tex, coords_tex.st);

              return color;
          }
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              return bob_and_slide(coords_geo, size_geo);
          }
        '';
      };
      "window-resize" = {
        custom-shader = ''
          vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
              vec3 coords_tex_next = niri_geo_to_tex_next * coords_curr_geo;
              vec4 color = texture2D(niri_tex_next, coords_tex_next.st);
              return color;
          }
        '';
      };
    };

    "glitch-cyberpunk" = {
      "window-open" = {
        duration-ms = 500;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) return vec4(0.0);
              float progress = niri_clamped_progress;
              float glitch = 1.0 - progress;
              vec2 uv = coords_geo.xy;

              // Horizontal displacement
              float glitch_bar = step(0.90, hash(vec2(floor(uv.y * 20.0), niri_random_seed)));
              float h_offset = glitch_bar * glitch * 0.15 * (hash(vec2(uv.y, niri_random_seed)) - 0.5);
              uv.x += h_offset;

              // RGB split. red leads, cyan trails
              float split = glitch * 0.12;
              vec3 cr = niri_geo_to_tex * vec3(uv + vec2(split * 1.5, split * 0.3), 1.0);
              vec3 cg = niri_geo_to_tex * vec3(uv, 1.0);
              vec3 cb = niri_geo_to_tex * vec3(uv - vec2(split, -split * 0.2), 1.0);

              float r = texture2D(niri_tex, cr.st).r;
              float g = texture2D(niri_tex, cg.st).g;
              float b = texture2D(niri_tex, cb.st).b;
              float a = texture2D(niri_tex, cg.st).a;
              vec3 color = vec3(r, g, b);

              // Noiseyy
              float noise = hash(uv * 500.0 + niri_random_seed) * glitch * 0.30;
              color += noise;

              // Red/magenta tint overlay stronger during glitch
              vec3 cyberpunk_tint = vec3(1.0, 0.2, 0.4);
              color = mix(color, color * cyberpunk_tint, glitch * 0.4);

              // Boost red channel
              color.r *= 1.0 + glitch * 0.3;

              // CRT scanlines with red tint
              float scanline = 1.0 - 0.12 + 0.12 * sin(uv.y * 450.0);
              color *= scanline;

              // Neon edge glow
              float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
              float glow = smoothstep(0.0, 0.15, edge);
              vec3 neon_red = vec3(1.0, 0.1, 0.3);
              color += neon_red * (1.0 - glow) * glitch * 1.0;

              return vec4(color, a * progress);
          }
        '';
      };
      "window-close" = {
        duration-ms = 700;
        curve = "linear";
        custom-shader = ''
          float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) return vec4(0.0);
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;

              // Progressive horizontal bars
              float glitch_bar = step(0.85 - progress * 0.1, hash(vec2(floor(uv.y * 25.0), niri_random_seed + progress)));
              float h_offset = glitch_bar * progress * 0.20 * (hash(vec2(uv.y, niri_random_seed)) - 0.5);
              uv.x += h_offset;

              // Vertical tear effect
              float tear = step(0.97, hash(vec2(floor(uv.x * 40.0), niri_random_seed)));
              uv.y += tear * progress * 0.08 * (hash(vec2(uv.x, niri_random_seed)) - 0.5);

              // RGB split
              float split = progress * 0.15;
              vec3 cr = niri_geo_to_tex * vec3(uv + vec2(split * 1.5, split * 0.4), 1.0);
              vec3 cg = niri_geo_to_tex * vec3(uv + vec2(0.0, progress * 0.02), 1.0);
              vec3 cb = niri_geo_to_tex * vec3(uv - vec2(split, -split * 0.3), 1.0);

              float r = texture2D(niri_tex, cr.st).r;
              float g = texture2D(niri_tex, cg.st).g;
              float b = texture2D(niri_tex, cb.st).b;
              float a = texture2D(niri_tex, cg.st).a;
              vec3 color = vec3(r, g, b);

              // Static noise
              float noise = hash(uv * 600.0 + niri_random_seed + progress * 10.0) * progress * 0.40;
              color += noise;

              // Red/magenta corruption
              vec3 cyberpunk_tint = vec3(1.0, 0.15, 0.35);
              color = mix(color, color * cyberpunk_tint, progress * 0.5);

              // Boost red, crush other channels as it dies
              color.r *= 1.0 + progress * 0.5;
              color.g *= 1.0 - progress * 0.3;
              color.b *= 1.0 - progress * 0.2;

              // Scanlines intensify
              float scanline = 1.0 - (0.08 + progress * 0.1) + (0.08 + progress * 0.1) * sin(uv.y * 500.0);
              color *= scanline;

              // Neon edge glow
              float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
              float glow = smoothstep(0.0, 0.08, edge);
              vec3 neon_red = vec3(1.0, 0.05, 0.25);
              color += neon_red * (1.0 - glow) * progress * 1.2;

              // Pixel flicker
              float hot_pixel = step(0.990, hash(uv * 300.0 + progress * 5.0));
              color += vec3(1.0, 0.3, 0.5) * hot_pixel * progress;

              return vec4(color, a * (1.0 - progress));
          }
        '';
      };
    };

    "glitch" = {
      "window-open" = {
        duration-ms = 700;
        curve = "linear";
        custom-shader = ''
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) return vec4(0.0);
              float progress = niri_clamped_progress;
              float glitch = 1.0 - progress;
              vec2 uv = coords_geo.xy;

              // RGB channel splitting - channels converge as window opens
              float split = glitch * 0.04;
              vec3 cr = niri_geo_to_tex * vec3(uv + vec2(split, 0.0), 1.0);
              vec3 cg = niri_geo_to_tex * vec3(uv, 1.0);
              vec3 cb = niri_geo_to_tex * vec3(uv - vec2(split, 0.0), 1.0);

              float r = texture2D(niri_tex, cr.st).r;
              float g = texture2D(niri_tex, cg.st).g;
              float b = texture2D(niri_tex, cb.st).b;
              float a = texture2D(niri_tex, cg.st).a;
              vec3 color = vec3(r, g, b);

              // CRT scanline effect
              float scanline = 1.0 - 0.12 + 0.12 * sin(uv.y * 450.0);

              return vec4(color * scanline, a * progress);
          }
        '';
      };
      "window-close" = {
        duration-ms = 1000;
        curve = "linear";
        custom-shader = ''
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) return vec4(0.0);
              float progress = niri_clamped_progress;
              vec2 uv = coords_geo.xy;

              // RGB channel splitting - channels separate as window closes
              float split = progress * 0.04;
              vec3 cr = niri_geo_to_tex * vec3(uv + vec2(split, 0.0), 1.0);
              vec3 cg = niri_geo_to_tex * vec3(uv, 1.0);
              vec3 cb = niri_geo_to_tex * vec3(uv - vec2(split, 0.0), 1.0);

              float r = texture2D(niri_tex, cr.st).r;
              float g = texture2D(niri_tex, cg.st).g;
              float b = texture2D(niri_tex, cb.st).b;
              float a = texture2D(niri_tex, cg.st).a;
              vec3 color = vec3(r, g, b);

              // CRT scanline effect
              float scanline = 1.0 - 0.12 + 0.12 * sin(uv.y * 450.0);

              return vec4(color * scanline, a * (1.0 - progress));
          }
        '';
      };
    };

    "halftone" = {
      "window-open" = {
        duration-ms = 500;
        curve = "linear";
        custom-shader = ''
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 color = texture2D(niri_tex, coords_tex.st);
              float cellSize = 35.0;

              float p = niri_clamped_progress * (1.0 + cellSize * 0.015);
              vec2 coords = (coords_geo.xy - vec2(0.5, 0.5)) * size_geo.xy / size_geo.x;
              coords*= cellSize;
              coords.x += ceil(coords.y) * .5;
              vec2 cell = floor(-coords);
              coords = fract(coords);

              vec2 center = vec2(0.5);
              float offset = cell.y ;
              float d = distance(coords, center);
              float r = p + offset / cellSize;
              if (r < 0.25) {
               r = 0.0;
              }
              d = smoothstep(r-0.01, r+0.01, d);
              vec4 col = mix(color, vec4(0), d);
              return col;
          }
        '';
      };
      "window-close" = {
        duration-ms = 500;
        curve = "linear";
        custom-shader = ''
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 color = texture2D(niri_tex, coords_tex.st);
              float cellSize = 35.0;

              float p = niri_clamped_progress * (1.0 + cellSize * 0.015);
              vec2 coords = (coords_geo.xy - vec2(0.0, 0.5)) * size_geo.xy / size_geo.x;
              coords*= cellSize;
              coords.x += ceil(coords.y) * .5;
              vec2 cell = floor(-coords);
              coords = fract(coords);

              vec2 center = vec2(0.5);
              float offset = cell.y ;
              float d = distance(coords, center);
              float r = 1.0 - p + offset / cellSize;
              if (r < 0.25) {
               r = 0.0;
              }
              d = smoothstep(r-0.01, r+0.01, d);
              vec4 col = mix(color, vec4(0), d);
              return col;
          }
        '';
      };
    };

    "pixelate" = {
      "window-open" = {
        duration-ms = 700;
        curve = "linear";
        custom-shader = ''
          vec4 pixelate_open(vec3 coords_geo, vec3 size_geo) {
              // Discard pixels outside window bounds
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) {
                  return vec4(0.0);
              }
              float progress = niri_clamped_progress;
              float border_width = 0.008; // Adjust based on your border size
              vec2 coords = coords_geo.xy;
              // Check if we're in the border region
              bool in_border = coords.x < border_width || coords.x > (1.0 - border_width) ||
                              coords.y < border_width || coords.y > (1.0 - border_width);
              // Only pixelate the inner content, not the border
              if (!in_border) {
                  float pixel_size = (1.0 - progress) * 0.1;
                  if (pixel_size > 0.0) {
                      coords = floor(coords / pixel_size) * pixel_size + pixel_size * 0.5;
                  }
                  // Clamp sampling to avoid border area
                  coords = clamp(coords, border_width, 1.0 - border_width);
              }
              vec3 new_coords = vec3(coords, 1.0);
              vec3 coords_tex = niri_geo_to_tex * new_coords;
              vec4 color = texture2D(niri_tex, coords_tex.st);
              color.a *= progress;
              return color;
          }
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
            return pixelate_open(coords_geo, size_geo);
          }
        '';
      };
      "window-close" = {
        duration-ms = 700;
        curve = "linear";
        custom-shader = ''
          vec4 pixelate_close(vec3 coords_geo, vec3 size_geo) {
              // Discard pixels outside window bounds
              if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) {
                  return vec4(0.0);
              }
              float progress = niri_clamped_progress;
              float border_width = 0.008;
              vec2 coords = coords_geo.xy;
              // Check if we're in the border region
              bool in_border = coords.x < border_width || coords.x > (1.0 - border_width) ||
                              coords.y < border_width || coords.y > (1.0 - border_width);
              // Only pixelate the inner content, not the border
              if (!in_border) {
                  float pixel_size = progress * 0.1;
                  if (pixel_size > 0.0) {
                      coords = floor(coords / pixel_size) * pixel_size + pixel_size * 0.5;
                  }
                  // Clamp sampling to avoid border area
                  coords = clamp(coords, border_width, 1.0 - border_width);
              }
              vec3 new_coords = vec3(coords, 1.0);
              vec3 coords_tex = niri_geo_to_tex * new_coords;
              vec4 color = texture2D(niri_tex, coords_tex.st);
              color.a *= (1.0 - progress);
              return color;
          }
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
            return pixelate_close(coords_geo, size_geo);
          }
        '';
      };
    };

    "pop-drop" = {
      "window-open" = {
        duration-ms = 700;
        curve = "ease-out-quad";
        custom-shader = ''
          vec4 zoom_in(vec3 coords_geo, vec3 size_geo) {
            float progress = niri_clamped_progress;
            float scale = progress;
            vec2 coords = (coords_geo.xy - vec2(0.5, 0.5)) * size_geo.xy;
            coords = coords / scale;
            coords_geo = vec3(coords / size_geo.xy + vec2(0.5, 0.5), 1.0);
            vec3 coords_tex = niri_geo_to_tex * coords_geo;
            vec4 color = texture2D(niri_tex, coords_tex.st);
            color.a *= progress;

            return color;
          }
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
            return zoom_in(coords_geo, size_geo);
          }
        '';
      };
      "window-close" = {
        duration-ms = 700;
        curve = "linear";
        custom-shader = ''
          vec4 fall_and_rotate(vec3 coords_geo, vec3 size_geo) {
            float progress = niri_clamped_progress * niri_clamped_progress;
            vec2 coords = (coords_geo.xy - vec2(0.5, 1.0)) * size_geo.xy;
            coords.y -= progress * 1440.0;
            float random = (niri_random_seed - 0.5) / 2.0;
            random = sign(random) - random;
            float max_angle = 0.5 * random;
            float angle = progress * max_angle;
            mat2 rotate = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
            coords = rotate * coords;
            coords_geo = vec3(coords / size_geo.xy + vec2(0.5, 1.0), 1.0);
            vec3 coords_tex = niri_geo_to_tex * coords_geo;
            vec4 color = texture2D(niri_tex, coords_tex.st);
            color.a *= (1.0 - progress);

            return color;
          }
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
            return fall_and_rotate(coords_geo, size_geo);
          }
        '';
      };
    };

    "ribbons" = {
      "window-open" = {
        duration-ms = 700;
        curve = "ease-out-quad";
        custom-shader = ''
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              float progress = niri_clamped_progress;

              // Completely random angle (0 to 2*PI)
              float random_angle = niri_random_seed * 6.28318;

              // Rotate the coordinates to create tilted ribbons
              vec2 coords = coords_geo.xy - 0.5;
              float cos_a = cos(random_angle);
              float sin_a = sin(random_angle);
              vec2 rotated = vec2(
                  coords.x * cos_a - coords.y * sin_a,
                  coords.x * sin_a + coords.y * cos_a
              );

              // Now work with rotated Y position for ribbon indexing
              float y_pos = rotated.y + 0.5;

              // Equal-sized ribbons (20 total)
              float ribbon_count = 30.0;
              float ribbon_index = floor(y_pos * ribbon_count);

              // Alternating pattern: even = left, odd = right
              float is_even = step(mod(ribbon_index, 2.0), 0.5);
              float direction = is_even * -2.0 + 1.0;

              // Cascading delay
              float delay = ribbon_index / ribbon_count * 0.5;
              float ribbon_progress = clamp((progress - delay) / (1.0 - delay), 0.0, 1.0);

              // Slide along the rotated X axis
              rotated.x += (1.0 - ribbon_progress) * direction * 2.0;

              // Rotate back to get final coordinates
              coords = vec2(
                  rotated.x * cos_a + rotated.y * sin_a,
                  -rotated.x * sin_a + rotated.y * cos_a
              );
              coords += 0.5;

              // Regular sampling
              vec3 coords_tex = niri_geo_to_tex * vec3(coords.x, coords.y, 1.0);
              vec4 color = texture2D(niri_tex, coords_tex.xy);

              // Check if ribbon hasn't arrived yet
              if (coords.x < 0.0 || coords.x > 1.0) {
                  return vec4(0.0);
              }

              return color;
          }
        '';
      };
      "window-close" = {
        duration-ms = 700;
        curve = "ease-out-quad";
        custom-shader = ''
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              float progress = niri_clamped_progress;

              // Completely random angle (0 to 2*PI)
              float random_angle = niri_random_seed * 6.28318;

              // Rotate the coordinates to create tilted ribbons
              vec2 coords = coords_geo.xy - 0.5; // center
              float cos_a = cos(random_angle);
              float sin_a = sin(random_angle);
              vec2 rotated = vec2(
                  coords.x * cos_a - coords.y * sin_a,
                  coords.x * sin_a + coords.y * cos_a
              );

              // Now work with rotated Y position for ribbon indexing
              float y_pos = rotated.y + 0.5;

              // Equal-sized ribbons (20 total)
              float ribbon_count = 30.0;
              float ribbon_index = floor(y_pos * ribbon_count);

              // Alternating pattern: even = left, odd = right
              float is_even = step(mod(ribbon_index, 2.0), 0.5);
              float direction = is_even * -2.0 + 1.0;

              // Cascading delay
              float delay = ribbon_index / ribbon_count * 0.5;
              float ribbon_progress = clamp((progress - delay) / (1.0 - delay), 0.0, 1.0);

              // Slide along the rotated X axis
              rotated.x += ribbon_progress * direction * 2.0;

              // Rotate back to get final coordinates
              coords = vec2(
                  rotated.x * cos_a + rotated.y * sin_a,
                  -rotated.x * sin_a + rotated.y * cos_a
              );
              coords += 0.5; // uncenter

              // Regular sampling
              vec3 coords_tex = niri_geo_to_tex * vec3(coords.x, coords.y, 1.0);
              vec4 color = texture2D(niri_tex, coords_tex.xy);

              // Check if ribbon has moved out of bounds
              if (coords.x < 0.0 || coords.x > 1.0) {
                  return vec4(0.0);
              }

              return color;
          }
        '';
      };
      "window-resize" = {
        custom-shader = ''
          vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
              vec3 coords_tex_next = niri_geo_to_tex_next * coords_curr_geo;
              vec4 color = texture2D(niri_tex_next, coords_tex_next.st);
              return color;
          }
        '';
      };
    };

    "roll-drop" = {
      "window-open" = {
        duration-ms = 1000;
        curve = "ease-out-expo";
        custom-shader = ''
          vec4 fall_from_top(vec3 coords_geo, vec3 size_geo) {
                      float progress = niri_clamped_progress * niri_clamped_progress;
                      vec2 coords = (coords_geo.xy - vec2(0.5, 0.0)) * size_geo.xy;
                      coords.y += (1.0 - progress) * 1440.0;
                      float max_angle = mix(-0.5, 0.5, floor(niri_random_seed * 4.0) / 3.0);
                      float angle = (1.0 - progress) * max_angle;
                      mat2 rotate = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
                      coords = rotate * coords;
                      coords_geo = vec3(coords / size_geo.xy + vec2(0.5, 0.0), 1.0);
                      vec3 coords_tex = niri_geo_to_tex * coords_geo;
                      return texture2D(niri_tex, coords_tex.st);
                  }
                  vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                      return fall_from_top(coords_geo, size_geo);
                  }
        '';
      };
      "window-close" = {
        duration-ms = 1000;
        curve = "linear";
        custom-shader = ''
          vec4 fall_to_bottom(vec3 coords_geo, vec3 size_geo) {
                      float progress = niri_clamped_progress * niri_clamped_progress;
                      vec2 coords = (coords_geo.xy - vec2(0.5, 0.0)) * size_geo.xy;
                      coords.y -= progress * 1440.0;
                      float max_angle = mix(-0.5, 0.5, floor(niri_random_seed * 4.0) / 3.0);
                      float angle = progress * max_angle;
                      mat2 rotate = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
                      coords = rotate * coords;
                      coords_geo = vec3(coords / size_geo.xy + vec2(0.5, 0.0), 1.0);
                      vec3 coords_tex = niri_geo_to_tex * coords_geo;
                      return texture2D(niri_tex, coords_tex.st);
                  }
                  vec4 close_color(vec3 coords_geo, vec3 size_geo) {
                      return fall_to_bottom(coords_geo, size_geo);
                  }
        '';
      };
    };

    "swipe-window" = {
      "window-open" = {
        duration-ms = 1400;
        curve = "ease-out-expo";
        custom-shader = ''
          float ease_curve(float x) {
              return x < 0.5 ? 4.0*x*x*x : 1.0 - pow(-2.0*x + 2.0, 3.0)/2.0;
          }

          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              float t = niri_clamped_progress;
              float prog = ease_curve(t);

              // choose corner: 0=top-left,1=top-right,2=bottom-left,3=bottom-right

              int corner = 3;
              vec2 start;
              vec2 dir;
              if (corner == 0) {
                  start = vec2(0.0,0.0);
                  dir = vec2(1.0,1.0);
              } else if (corner == 1) {
                  start = vec2(1.0,0.0);
                  dir = vec2(-1.0,1.0);
              } else if (corner == 2) {
                  start = vec2(0.0,1.0);
                  dir = vec2(1.0,-1.0);
              } else {
                  start = vec2(1.0,1.0);
                  dir = vec2(-1.0,-1.0);
              }

              // compute distance along diagonal from corner
              vec2 p = coords_geo.xy;
              float dist = dot(p - start, dir);

              // normalize distance to max diagonal (from corner to opposite)
              float max_diag = 2.0;
              float norm_dist = dist / max_diag;

              // pixels not yet reached by sweep are invisible
              if (norm_dist > prog) {
                  return vec4(0.0);
              }

              // sample normally
              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 col = texture2D(niri_tex, coords_tex.xy);

              return col;
          }
        '';
      };
      "window-close" = {
        duration-ms = 1400;
        curve = "ease-out-expo";
        custom-shader = ''
          // ease-in-out cubic curve helper
          float ease_curve(float x) {
              return x < 0.5 ? 4.0*x*x*x : 1.0 - pow(-2.0*x + 2.0, 3.0)/2.0;
          }

          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              float t = niri_clamped_progress;


              float prog = ease_curve(t);

              // choose corner: 0=top-left,1=top-right,2=bottom-left,3=bottom-right

              int corner = 0;
              vec2 start;
              vec2 dir;
              if (corner == 0) {
                  start = vec2(0.0,0.0);
                  dir = vec2(1.0,1.0);
              } else if (corner == 1) {
                  start = vec2(1.0,0.0);
                  dir = vec2(-1.0,1.0);
              } else if (corner == 2) {
                  start = vec2(0.0,1.0);
                  dir = vec2(1.0,-1.0);
              } else {
                  start = vec2(1.0,1.0);
                  dir = vec2(-1.0,-1.0);
              }

              float shadow_fix = 0.01; // otherwise the animation may stop before
              // it hides the shadow, since it's outside the window bounds

              // compute distance along diagonal from corner

              vec2 p = coords_geo.xy;
              float dist = dot(p - start, dir) - shadow_fix;

              // normalize distance to max diagonal
              float max_diag = 2.0; // max of vec2(1,1)
              float norm_dist = dist / max_diag;


              // If pixel is behind the sweeping line, make it invisible

              if (norm_dist <= prog) {
                  return vec4(0.0);
              }

              // sample normally
              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 col = texture2D(niri_tex, coords_tex.xy);

              return col;
          }
        '';
      };
      "window-resize" = {
        custom-shader = ''
          vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
              vec3 coords_tex_next = niri_geo_to_tex_next * coords_curr_geo;
              vec4 color = texture2D(niri_tex_next, coords_tex_next.st);
              return color;
          }
        '';
      };
    };

    "unravel" = {
      "window-open" = {
        duration-ms = 700;
        curve = "ease-out-expo";
        custom-shader = ''
          vec4 line_expand(vec3 coords_geo, vec3 size_geo) {
              float progress = niri_clamped_progress;

              // Add extra easing on top of the curve
              float eased_progress = progress * progress * (3.0 - 2.0 * progress); // smoothstep

              // Calculate the center of the window
              float window_center_y = size_geo.y * 0.5;

              // Current pixel's Y position
              float pixel_y = coords_geo.y * size_geo.y;

              // Distance from center
              float dist_from_center = abs(pixel_y - window_center_y);

              // How much of the window should be visible
              float visible_radius = (size_geo.y * 0.5) * eased_progress;

              // If outside visible area, hide it
              if (dist_from_center > visible_radius) {
                  return vec4(0.0);
              }

              // Draw a bright line at the expanding edges (top and bottom)
              float edge_thickness = 3.0;
              bool at_edge = abs(dist_from_center - visible_radius) < edge_thickness;

              // Show the pixel
              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 color = texture2D(niri_tex, coords_tex.st);

              // Make the edge line bright white
              if (at_edge && eased_progress < 0.99) {
                  color.rgb = mix(color.rgb, vec3(1.0, 1.0, 1.0), 0.8);
              }

              return color;
          }
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              return line_expand(coords_geo, size_geo);
          }
        '';
      };
      "window-close" = {
        duration-ms = 500;
        curve = "ease-out-expo";
        custom-shader = ''
          vec4 line_collapse(vec3 coords_geo, vec3 size_geo) {
              float progress = niri_clamped_progress;

              // Add extra easing on top of the curve
              float eased_progress = progress * progress * (3.0 - 2.0 * progress); // smoothstep

              // Reverse the progress so it goes from full to line
              float reversed_progress = 1.0 - eased_progress;

              // Calculate the center of the window
              float window_center_y = size_geo.y * 0.5;

              // Current pixel's Y position
              float pixel_y = coords_geo.y * size_geo.y;

              // Distance from center
              float dist_from_center = abs(pixel_y - window_center_y);

              // How much of the window should be visible (shrinking)
              float visible_radius = (size_geo.y * 0.5) * reversed_progress;

              // If outside visible area, hide it
              if (dist_from_center > visible_radius) {
                  return vec4(0.0);
              }

              // Draw a bright line at the collapsing edges
              float edge_thickness = 2.0;
              bool at_edge = abs(dist_from_center - visible_radius) < edge_thickness;

              // Show the pixel
              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 color = texture2D(niri_tex, coords_tex.st);

              // Make the edge line bright white
              if (at_edge && reversed_progress > 0.01) {
                  color.rgb = mix(color.rgb, vec3(1.0, 1.0, 1.0), 0.8);
              }

              return color;
          }
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              return line_collapse(coords_geo, size_geo);
          }
        '';
      };
      "window-resize" = {
        custom-shader = ''
          vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
              vec3 coords_tex_next = niri_geo_to_tex_next * coords_curr_geo;
              vec4 color = texture2D(niri_tex_next, coords_tex_next.st);
              return color;
          }
        '';
      };
    };
  };
}
