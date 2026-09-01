# Chromium-backed standalone web applications ("SSBs").
#
# Each entry in `webapps.<name>` produces:
#   * a launcher script  `webapp-<name>`  (chromium --app=<url> with its own profile)
#   * a .desktop entry   `webapp-<name>.desktop`
#   * optionally an icon installed into hicolor/scalable
#
# Widevine is opted into per-app; if any app requests it the shared chromium
# is overridden with `enableWideVine = true`. That override only rebuilds the
# thin wrapper derivation, not chromium itself, so it comes off the binary cache.
{ config, lib, ... }:

let
  inherit (lib) mkOption types;

  webappOpts =
    { name, config, ... }:
    {
      options = {
        url = mkOption {
          type = types.str;
          example = "https://www.crunchyroll.com/";
          description = "URL opened in app mode.";
        };

        displayName = mkOption {
          type = types.str;
          default = name;
          description = "Name shown in the application launcher.";
        };

        comment = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Desktop entry Comment field.";
        };

        categories = mkOption {
          type = types.listOf types.str;
          default = [ "Network" ];
          description = "Freedesktop menu categories.";
        };

        widevine = mkOption {
          type = types.bool;
          default = false;
          description = "Whether this app needs the Widevine CDM (DRM streaming).";
        };

        appId = mkOption {
          type = types.str;
          default = "webapp-${name}";
          description = ''
            Wayland app_id / X11 WM_CLASS. Passed as `--class` and used as
            StartupWMClass so niri window rules can target the app.
          '';
        };

        iconFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "SVG installed as the app icon. Null uses `iconName` as-is.";
        };

        iconName = mkOption {
          type = types.str;
          default = if config.iconFile != null then "webapp-${name}" else "chromium";
          defaultText = lib.literalExpression ''"webapp-<name>" or "chromium"'';
          description = "Icon name referenced by the desktop entry.";
        };

        profileDir = mkOption {
          type = types.str;
          default = name;
          description = "Directory under $XDG_DATA_HOME/webapps holding this app's chromium profile.";
        };

        extraFlags = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "--force-dark-mode" ];
          description = "Extra chromium flags for this app only.";
        };
      };
    };

  # Loose stand-in mark so the launcher entry isn't a bare chromium globe.
  # Swap in the real artwork by pointing `iconFile` at your own SVG/PNG.
  crunchyrollIcon = builtins.toFile "crunchyroll.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
      <rect width="128" height="128" rx="28" fill="#F47521"/>
      <path d="M92 64a28 28 0 1 1-28-28" fill="none" stroke="#ffffff"
            stroke-width="12" stroke-linecap="round"/>
      <circle cx="86" cy="42" r="9" fill="#ffffff"/>
    </svg>
  '';
in
{
  options.webapps = mkOption {
    type = types.attrsOf (types.submodule webappOpts);
    default = { };
    description = "Standalone chromium web applications installed system-wide.";
  };

  config = {
    webapps.crunchyroll = {
      url = "https://www.crunchyroll.com/";
      displayName = "Crunchyroll";
      comment = "Anime streaming";
      categories = [
        "AudioVideo"
        "Video"
        "Player"
      ];
      widevine = true;
      appId = "crunchyroll";
      iconFile = crunchyrollIcon;
      extraFlags = [ "--force-dark-mode" ];
    };

    flake.nixosModules.webapps =
      { pkgs, lib, ... }:
      let
        apps = lib.attrValues config.webapps;

        anyWidevine = lib.any (app: app.widevine) apps;

        chromiumPkg =
          if anyWidevine then pkgs.chromium.override { enableWideVine = true; } else pkgs.chromium;

        chromiumExe = lib.getExe' chromiumPkg "chromium";

        mkLauncher =
          app:
          pkgs.writeShellScriptBin "webapp-${app.appId}" ''
            profile="''${XDG_DATA_HOME:-$HOME/.local/share}/webapps/${app.profileDir}"
            mkdir -p "$profile"
            exec ${chromiumExe} \
              --user-data-dir="$profile" \
              --class=${lib.escapeShellArg app.appId} \
              --no-first-run \
              --no-default-browser-check \
              --app=${lib.escapeShellArg app.url} \
              ${lib.escapeShellArgs app.extraFlags} "$@"
          '';

        mkIcon =
          app:
          pkgs.runCommand "webapp-icon-${app.appId}" { } ''
            install -Dm444 ${app.iconFile} \
              "$out/share/icons/hicolor/scalable/apps/${app.iconName}.svg"
          '';

        mkDesktopItem =
          app:
          pkgs.makeDesktopItem {
            name = "webapp-${app.appId}";
            desktopName = app.displayName;
            comment = app.comment;
            exec = "webapp-${app.appId}";
            icon = app.iconName;
            categories = app.categories;
            startupWMClass = app.appId;
            startupNotify = true;
            terminal = false;
          };
      in
      {
        environment.systemPackages = lib.concatMap (
          app:
          [
            (mkLauncher app)
            (mkDesktopItem app)
          ]
          ++ lib.optional (app.iconFile != null) (mkIcon app)
        ) apps;
      };
  };
}
