{ config, lib, ... }:
let
  # One theme = one value of this submodule. Every knob a theme can own
  # lives here; adding a custom theme is just a new file doing
  # `theme.themes.<name> = { ... }` — no enum to extend, no mkIf chains.
  themeType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        palette = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = ''
            Canonical named hex colors for this theme. Consumers (home/kitty.nix,
            steam.nix's MangoHud, niri.nix's focus-ring) read these via the
            theme.palette alias. Expected keys: accent accent2 void foreground
            red yellow green cyan blue — readers fall back per-key, so a
            partial palette degrades gracefully instead of failing eval.
          '';
        };

        gtkTheme = lib.mkOption {
          type = lib.types.str;
          default = "adw-gtk3-dark";
          description = "GTK theme name (adw-gtk3/adw-gtk3-dark for Noctalia color sync).";
        };
        iconTheme = lib.mkOption {
          type = lib.types.str;
          default = "candy-icons";
          description = "GTK icon theme name.";
        };
        cursorTheme = lib.mkOption {
          type = lib.types.str;
          default = "Banana";
          description = "XCursor theme name.";
        };

        noctaliaPredefinedScheme = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            Noctalia colorSchemes.predefinedScheme. Empty string lets
            useWallpaperColors + Material Gen drive it from the wallpaper.
          '';
        };
        darkMode = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Noctalia colorSchemes.darkMode for this theme.";
        };

        wallpaperDir = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = ''
            Subdirectory of theme.wallpapersBase this theme draws wallpapers
            from. Defaults to the theme's own name (wallpaper/<theme>/).
            Noctalia's random rotation then only ever picks from the active
            theme's set. A plain runtime path on purpose — dropping a new
            image into the folder needs no rebuild, and Noctalia's favorites
            keep stable paths instead of churning store hashes.
          '';
        };
        fillColor = lib.mkOption {
          type = lib.types.str;
          default = "#000000";
          description = "Noctalia wallpaper.fillColor (letterbox bars when fillMode leaves gaps).";
        };

        sddmThemes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Pool the sddm-random-theme oneshot picks from at boot, for this
            theme. Valid names = directory names in the pinned qylock flake's
            themes/ (e.g. pixel-cyberpunk, star-rail, R1999_1, nothing,
            girl-coffee). Empty list = skip the randomizer entirely and let
            programs.qylock's own SDDM default (qylockTheme) stand.
          '';
        };
        qylockTheme = lib.mkOption {
          type = lib.types.str;
          default = "nier-automata";
          description = "qylock lock-screen theme (also the SDDM baseline theme qylock sets).";
        };

        terminalOpacity = lib.mkOption {
          type = lib.types.float;
          default = 1.0;
          description = ''
            Kitty background_opacity — background-only transparency, text
            stays fully crisp. This is why the terminal is NOT in
            niri.appOpacity: a niri window rule would fade the glyphs too.
          '';
        };

        spicetifyColorScheme = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            Color scheme for Spicetify's "text" theme. Valid names come from
            the theme's color.ini ([TokyoNight], [Gruvbox], [Nord],
            [Dracula], [CatppuccinMocha], ...). Empty = the theme's default.
          '';
        };

        niri = {
          inactiveColor = lib.mkOption {
            type = lib.types.str;
            default = "#2a2a2a";
            description = "Focus-ring color of unfocused windows.";
          };
          gaps = lib.mkOption {
            type = lib.types.int;
            default = 8;
            description = "Gap size between windows/columns.";
          };
          cornerRadius = lib.mkOption {
            type = lib.types.int;
            default = 12;
            description = "Window corner radius (geometry-corner-radius).";
          };
          windowOpacity = lib.mkOption {
            type = lib.types.float;
            default = 1.0;
            description = ''
              Default opacity for ALL windows. 1.0 = opaque; per-app
              transparency belongs in appOpacity instead of here (the old
              global 0.90 made everything see-through).
            '';
          };
          appOpacity = lib.mkOption {
            type = lib.types.attrsOf lib.types.float;
            default = { };
            example = {
              "^(codium|VSCodium)$" = 0.92;
            };
            description = ''
              app-id regex -> opacity, rendered as niri window-rules that
              override windowOpacity for matching windows. Check real
              app-ids with `niri msg windows`.
            '';
          };
          pipOpacity = lib.mkOption {
            type = lib.types.float;
            default = 1.0;
            description = ''
              Opacity of the floating Picture-in-Picture window. Its rule
              also forces background-effect.blur off, so the video shows
              through cleanly instead of frosted.
            '';
          };
          glitchShader = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable the cyberpunk glitch open/close shaders. Off = niri's stock animations.";
          };
        };
      };
    }
  );
in
{
  # ------------------------------------------------------------------
  # The registry + selector. Same flake-parts-level single-value caveat
  # as before: one host today (ws01-nix); a second same-arch host would
  # share the active theme until the perSystem wrap calls move per-host.
  # ------------------------------------------------------------------
  options.theme.themes = lib.mkOption {
    type = lib.types.attrsOf themeType;
    default = { };
    description = "All defined themes, keyed by name. One file per theme under theming/themes/.";
  };

  options.theme.active = lib.mkOption {
    type = lib.types.str;
    default = "cyberpunk";
    description = "Name of the active theme (a key of theme.themes). Change + rebuild to switch fully.";
  };

  options.theme.current = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    default =
      config.theme.themes.${config.theme.active}
        or (throw "theme.active = \"${config.theme.active}\" but theme.themes has no such theme (have: ${lib.concatStringsSep ", " (lib.attrNames config.theme.themes)})");
    description = "The active theme's evaluated settings — what consumer modules read.";
  };

  options.theme.wallpapersBase = lib.mkOption {
    type = lib.types.str;
    default = "/home/colt/Documents/NixOS/wallpaper";
    description = "Runtime path of the wallpaper root; each theme uses <base>/<wallpaperDir>.";
  };

  # ------------------------------------------------------------------
  # Aliases kept so existing consumers don't have to change what they
  # read: home/kitty.nix, steam.nix and niri.nix keep reading
  # theme.palette; noctalia.nix keeps reading noctaliaPredefinedScheme;
  # desktop/{theme,icons,cursor}.nix declare desktop.* and everything
  # (gtk-settings.nix, home/gtk.nix, home/cursor.nix, niri's cursor
  # block) keeps reading those.
  # ------------------------------------------------------------------
  options.theme.palette = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Alias of theme.current.palette — don't set directly, set it on the theme.";
  };
  options.theme.noctaliaPredefinedScheme = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = "Alias of theme.current.noctaliaPredefinedScheme.";
  };

  config = {
    theme.palette = config.theme.current.palette;
    theme.noctaliaPredefinedScheme = config.theme.current.noctaliaPredefinedScheme;

    # desktop.* options stay declared in desktop/{theme,icons,cursor}.nix;
    # the active theme now provides their values. A plain definition beats
    # the option defaults, and nothing else defines these anymore.
    desktop.gtkTheme = config.theme.current.gtkTheme;
    desktop.iconTheme = config.theme.current.iconTheme;
    desktop.cursorTheme = config.theme.current.cursorTheme;
  };

  # ------------------------------------------------------------------
  # Device-shape options (not theme-dependent) — unchanged from before.
  # ------------------------------------------------------------------
  options.device.class = lib.mkOption {
    type = lib.types.enum [
      "desktop"
      "laptop"
    ];
    default = "desktop";
    description = "Form factor. Gates mouse/font/theme defaults across other modules.";
  };

  options.desktop.fontScale = lib.mkOption {
    type = lib.types.float;
    default = 1.0;
    description = "Multiplier fed into Noctalia's ui.fontDefaultScale/fontFixedScale.";
  };
}
