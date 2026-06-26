{ self, inputs, ... }: {

  flake.nixosModules.zen = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.ZenConf
    ];
  };

  perSystem = { pkgs, lib, ... }: {
    packages.ZenConf =
      let
        # Given an AMO slug and extension GUID, produce a policy entry.
        # To find GUIDs for other extensions:
        #   https://addons.mozilla.org/api/v5/addons/addon/<slug>/
        extension = shortId: guid: {
          name = guid;
          value = {
            install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
            installation_mode = "normal_installed";
          };
        };

        prefs = {
          "extensions.autoDisableScopes" = 0; # allow policy-installed extensions to run
          "extensions.pocket.enabled" = false;
          "browser.startup.page" = 3; # restore previous session on launch
        };

        extensions = [
          (extension "ublock-origin" "uBlock0@raymondhill.net")
          (extension "proton-pass" "pass@proton.me")
          (extension "zen-internet" "{91aa3897-2634-4a8a-9092-279db23a7689}")
        ];

      in
      pkgs.wrapFirefox
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
        {
          extraPrefs = lib.concatLines (
            lib.mapAttrsToList (
              name: value: "lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});"
            ) prefs
          );

          extraPolicies = {
            DisableTelemetry = true;
            DisableFirefoxStudies = true;
            DisablePocket = true;
            OverrideFirstRunPage = ""; # skip the welcome/onboarding page

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
  };
}
