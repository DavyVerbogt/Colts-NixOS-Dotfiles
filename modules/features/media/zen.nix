{ self, inputs, ... }: {

  flake.nixosModules.zen =
    { pkgs, ... }:
    let
      chromeFiles = self.packages.${pkgs.stdenv.hostPlatform.system}.SineChromeFiles;

      # Sine (CosmoCreeper/Sine) bootstrap for the PROFILE side — see
      # perSystem.packages.SineChromeFiles below for what this seeds and
      # why it's a seed, not a forced sync. Written as its own script
      # (rather than inlined in the activationScript) so quoting stays sane
      # and to match the writeShellScript convention used elsewhere in the
      # repo (screenshot.nix, matugen.nix). Runs as colt via runuser, same
      # pattern as desktop/mimeapps.nix's userMimeDefaults, since this has
      # to write into colt's real $HOME, not the Nix store.
      sineBootstrapScript = pkgs.writeShellScript "sine-bootstrap" ''
        set -euo pipefail
        zen_dir="$HOME/.config/zen"
        [ -f "$zen_dir/profiles.ini" ] || exit 0

        ${pkgs.gnused}/bin/sed -n 's/^Path=//p' "$zen_dir/profiles.ini" | while IFS= read -r profile_path; do
          chrome_dir="$zen_dir/$profile_path/chrome"
          mkdir -p "$chrome_dir/sine-mods"

          if [ ! -d "$chrome_dir/utils" ]; then
            cp -r "${chromeFiles}/utils" "$chrome_dir/utils"
            chmod -R u+w "$chrome_dir/utils"
          fi
          if [ ! -d "$chrome_dir/JS" ]; then
            cp -r "${chromeFiles}/JS" "$chrome_dir/JS"
            chmod -R u+w "$chrome_dir/JS"
          fi
        done
      '';
    in
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.ZenConf
      ];

      system.activationScripts.sineBootstrap = {
        text = ''
          ${pkgs.util-linux}/bin/runuser -u colt -- ${sineBootstrapScript}
        '';
      };
    };

  perSystem = { pkgs, lib, ... }: {
    packages.ZenConf =
      let
        # Given an AMO slug and extension GUID, produce a policy entry.
        extension = shortId: guid: {
          name = guid;
          value = {
            install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
            installation_mode = "normal_installed";
          };
        };

        prefs = {
          "extensions.autoDisableScopes" = 0;
          "extensions.pocket.enabled" = false;
          "browser.startup.page" = 3;
        };

        extensions = [
          (extension "ublock-origin" "uBlock0@raymondhill.net")
          (extension "proton-pass" "pass@proton.me")
          (extension "zen-internet" "{91aa3897-2634-4a8a-9092-279db23a7689}")
        ];

        # --- Sine — program-side loader ------------------------------------
        # Verbatim program/config.js from sineorg/bootloader v0.1.4 (Sine's
        # own minimal loader — Sine 2.3+ dropped the fx-autoconfig
        # dependency, though the underlying Firefox mechanism is the same).
        # wrapFirefox's extraPrefsFiles appends this into mozilla.cfg, which
        # is what "general.config" executes on every startup. Downloaded
        # and diffed against the actual release asset, not retyped.
        sineBootloaderConfig = pkgs.writeText "sine-bootloader-config.js" ''
          // Loads Sine.
          if (!Services.appinfo.inSafeMode) {
            try {
              const cmanifest = Services.dirsvc.get("UChrm", Ci.nsIFile);
              cmanifest.append("utils");
              cmanifest.append("chrome.manifest");

              if (cmanifest.exists()) {
                Components.manager.QueryInterface(Ci.nsIComponentRegistrar).autoRegister(cmanifest);
                ChromeUtils.importESModule("chrome://userscripts/content/sine.sys.mjs");
              } else {
                Components.utils.reportError("[sine-debug] chrome.manifest not found at: " + cmanifest.path);
              }
            } catch (err) {
              Components.utils.reportError("[sine-debug] Sine failed to load: " + err + "\n" + (err && err.stack));
            }
          }
        '';

        zenWrapped =
          pkgs.wrapFirefox
            inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
            {
              extraPrefs = lib.concatLines (
                lib.mapAttrsToList (
                  name: value: "lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});"
                ) prefs
              );

              extraPrefsFiles = [ sineBootloaderConfig ];

              # general.config.sandbox_enabled=false has to land in
              # defaults/pref/autoconfig.js specifically — extraPrefs/
              # extraPrefsFiles can't reach that file, only mozilla.cfg (open
              # nixpkgs issue #299595). Without it, Sine's own try/catch
              # above silently swallows the sandbox violation — no error,
              # nothing loads.
              #
              # wrapFirefox has a built-in extraAutoConfig argument for
              # exactly this (writes straight into autoconfig.js as part of
              # its normal build: see pkgs/applications/networking/browsers/
              # firefox/wrapper.nix). Use that instead of copying and
              # hand-patching the built derivation after the fact — a prior
              # version of this file did that via cp -rL + sed, which broke
              # in two different ways (a stale exec path in the makeWrapper
              # launcher script, then omni.ja corruption from an overly
              # broad sed sweep) before landing on this simpler fix.
              extraAutoConfig = ''
                pref("general.config.sandbox_enabled", false);
              '';

              extraPolicies = {
                DisableTelemetry = true;
                DisableFirefoxStudies = true;
                DisablePocket = true;
                OverrideFirstRunPage = "";

                ExtensionSettings = builtins.listToAttrs extensions;

                SearchEngines = {
                  Default = "Qwant";
                  Add = [
                    {
                      Name = "Qwant";
                      URLTemplate = "https://www.qwant.com/?q={searchTerms}";
                      Method = "GET";
                      IconURL = "https://www.qwant.com/favicon.ico";
                      Alias = "@q";
                    }
                  ];
                };
              };
            };
      in
      zenWrapped;

    # --- Sine — profile-side chrome files ---------------------------------
    # Fetched, pinned Sine assets — see zen.nix's sineBootstrapScript above
    # for how these actually land in ~/.zen. Not auto-updating (bump the
    # hashes deliberately):
    #   sineorg/bootloader v0.1.4  -> profile.zip  (chrome/utils/*)
    #   CosmoCreeper/Sine  v2.3.3  -> engine.zip   (chrome/JS/*, includes
    #     locales as of this release — the standalone locales.zip asset
    #     from the install docs has been retired upstream, 404s now)
    # Hashes are the real sha256 of those exact release assets, verified by
    # downloading and hashing them directly — not guessed.
    packages.SineChromeFiles =
      let
        bootloaderProfile = pkgs.fetchurl {
          url = "https://github.com/sineorg/bootloader/releases/download/v0.1.4/profile.zip";
          hash = "sha256-KFs9WJzJefEfAcnHdBC3F2lMzE8yzBywi9bYkJ+5jgA=";
        };
        sineEngine = pkgs.fetchurl {
          url = "https://github.com/CosmoCreeper/Sine/releases/download/v2.3.3/engine.zip";
          hash = "sha256-yYvo4CNOjE1bQdwne9IBo2Wi3MQY3LqC1HSdJ6ZKPWU=";
        };
      in
      pkgs.runCommand "sine-chrome-files" { nativeBuildInputs = [ pkgs.unzip ]; } ''
        mkdir -p $out
        unzip -q ${bootloaderProfile} -d $out
        unzip -q ${sineEngine} -d $out
      '';
  };
}
