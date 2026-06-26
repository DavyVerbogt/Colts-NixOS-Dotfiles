{ self, lib, ... }: {

  # VSCodium configured entirely in Nix: extensions, themes, and settings.
  # Mirrors the niri.nix style — the wrapped package is built in `perSystem`
  # and the nixosModule just installs it.
  #
  # Imported in hosts/ws01-nix/config.nix as: self.nixosModules.vscodium
  # NOTE: remove plain `vscodium` from environment.systemPackages in config.nix
  #       so you don't end up with two copies.
  flake.nixosModules.vscodium = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.Vscodium
    ];
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "vscode-extension-anthropic-claude-code"
      ];
  };

  perSystem = { pkgs, lib, ... }: {

    packages.Vscodium =
      let

        # --- 1. Settings (the "settings way like niri") ---------------------
        # A normal Nix attrset, serialised to settings.json. Nix is the source
        # of truth: it is rewritten on every launch (GUI edits are replaced),
        # the same way niri regenerates its KDL config from `settings`.
        settingsFile = pkgs.writeText "vscodium-settings.json" (
          builtins.toJSON {
            "editor.fontSize" = 14;
            "editor.formatOnSave" = true;
            "files.autoSave" = "onFocusChange";
            "telemetry.telemetryLevel" = "off";

            # These two names must match the theme extensions added below.
            "workbench.colorTheme" = "Dracula Theme"; # [verify: theme's display name]
            "workbench.iconTheme" = "material-icon-theme";

            # --- Nix language + formatting (jnoortheen.nix-ide) ---
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "nil"; # nix LSP (bundled into PATH below)
            "nix.formatterPath" = "nixfmt"; # official formatter (nixfmt-rfc-style)
            # Use nix-ide as the formatter for .nix files, so format-on-save
            # runs nixfmt:
            "[nix]" = {
              "editor.defaultFormatter" = "jnoortheen.nix-ide";
            };
          }
        );

        # --- 2. The editor + extensions/themes -----------------------------
        # A theme is just an extension. Add/remove freely.
        # Find attribute names on search.nixos.org (search "vscode-extensions").
        editor = pkgs.vscode-with-extensions.override {
          vscode = pkgs.vscodium;
          vscodeExtensions =
            (with pkgs.vscode-extensions; [
              jnoortheen.nix-ide # Nix language support + formatting
              mkhl.direnv # direnv integration
              anthropic.claude-code
              pkief.material-icon-theme
              # pkief.material-icon-theme # icon theme   # [verify: attr name]
            ])
            # Fallback for extensions not packaged in nixpkgs — fetch
            # straight from the marketplace (you supply the sha256):
            ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
              # {
              #   name = "remote-ssh-edit";
              #   publisher = "ms-vscode-remote";
              #   version = "0.47.2";
              #   sha256 = "0000000000000000000000000000000000000000000000000000";
              # }
            ];
        };

      in
      # --- 3. Bake settings in + put nixfmt/nil on the editor's PATH ------
      # symlinkJoin + wrapProgram is the standard nixpkgs wrapping idiom.
      # --prefix PATH makes `nixfmt` and `nil` available to the nix-ide
      # extension regardless of what's installed system-wide.
      pkgs.symlinkJoin {
        name = "vscodium-configured";
        paths = [ editor ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/codium \
              --prefix PATH : ${
                lib.makeBinPath [
                  pkgs.nixfmt
                  pkgs.nil
                ]
              } \
              --run 'mkdir -p "''${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User"' \
              --run 'install -m600 ${settingsFile} "''${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User/settings.json"'
        '';
      };
  };
}
