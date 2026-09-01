{ self, inputs, ... }: {

  # Amethyst Mod Manager v2.0 (PySide6 Qt rewrite), built FROM SOURCE.
  #
  # Why from source: the upstream AppImages (1.3.x and 2.0.x) ship a corrupt
  # squashfs payload that neither appimage-run nor appimageTools.wrapType2
  # can extract ("Can't find a valid SQUASHFS superblock"). The app itself
  # is pure Python (no compiled step) driven by src/run_qt.py, so we skip
  # the AppImage entirely and run the source tree directly under a Nix
  # python3 that carries its deps.
  #
  # Packaging mirrors the upstream AUR PKGBUILD (src/appimage/PKGBUILD):
  #   - install the src/ tree to $out/share/amethyst-mod-manager
  #   - a launcher dispatches cli.py subcommands vs the run_qt.py GUI
  #   - PySide6 + the requirements-vendor.txt deps come from python3Packages
  #   - native helpers it shells out to (7z, bsdtar, zenity) are on PATH
  #   - qt6 wayland + imageformats (WebP thumbnails) via wrapQtAppsHook
  #
  # Source is a flake input pinned to a commit rev (flake.nix: amethyst-mm) —
  # NOT a tag: upstream deletes/re-points its beta tags, which breaks
  # `nix flake update`. Bumping the version means editing that rev in flake.nix.
  # `version` below is still read out of the source, so it follows automatically.
  #
  # Imported in hosts/ws01-nix/config.nix as: self.nixosModules.amm

  flake.nixosModules.amm =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.AmethystModManager
      ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.AmethystModManager =
        let
          src = inputs.amethyst-mm;

          version =
            let
              m = builtins.match ''.*__version__ = "([^"]+)".*''
                (builtins.readFile "${src}/src/version.py");
            in
            if m == null then "2.0.0-beta" else builtins.head m;

          # Runtime Python deps — the requirements-vendor.txt list plus
          # PySide6 (which the PKGBUILD takes from the platform, not vendored).
          pythonEnv = pkgs.python3.withPackages (ps: with ps; [
            pyside6
            py7zr
            libarchive-c
            pillow
            lz4
            zstandard
            requests
            websocket-client
            keyring
            jeepney
            importlib-metadata
            backports-tarfile
            msgpack
            bsdiff4
          ]);

          # Native tools the app shells out to (PKGBUILD bundles static 7zzs /
          # zenity / bsdtar; on NixOS we just put real ones on PATH).
          runtimePath = pkgs.lib.makeBinPath [
            pkgs.p7zip      # 7z / 7za
            pkgs.libarchive # bsdtar
            pkgs.zenity     # portal filechooser fallback (Utils/portal_filechooser.py)
          ];

          desktopItem = pkgs.makeDesktopItem {
            name = "amethyst-mod-manager";
            desktopName = "Amethyst Mod Manager";
            comment = "Linux-native mod manager for a variety of games";
            exec = "amethyst-mod-manager %u";
            icon = "amethyst-mod-manager";
            categories = [ "Game" "Utility" ];
            mimeTypes = [
              "x-scheme-handler/nxm"
              "x-scheme-handler/nxm-protocol"
            ];
          };
        in
        pkgs.stdenv.mkDerivation {
          pname = "amethyst-mod-manager";
          inherit version src;

          nativeBuildInputs = [
            pkgs.qt6.wrapQtAppsHook
            pkgs.makeWrapper
            pkgs.copyDesktopItems
          ];

          # PySide6 pulls Qt in; wrapQtAppsHook needs these visible.
          buildInputs = [
            pkgs.qt6.qtbase
            pkgs.qt6.qtwayland
            pkgs.qt6.qtimageformats # libqwebp — Nexus WebP thumbnails
          ];

          desktopItems = [ desktopItem ];

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            appdir="$out/share/amethyst-mod-manager"
            mkdir -p "$appdir"

            # Copy the whole src/ tree (app_bootstrap discovers Games/, icons/,
            # etc. relative to the script dir, so keep the layout intact).
            cp -r src/. "$appdir/"

            # Strip dev/build artefacts, matching the PKGBUILD's cleanup.
            find "$appdir" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
            find "$appdir" -type f -name '*.sh' -delete 2>/dev/null || true
            find "$appdir" -type f -name 'requirements*.txt' -delete 2>/dev/null || true

            # Icon for the launcher entry.
            if [ -f "$appdir/icons/title-bar.png" ]; then
              install -Dm644 "$appdir/icons/title-bar.png" \
                "$out/share/icons/hicolor/256x256/apps/amethyst-mod-manager.png"
            fi

            # Launcher: dispatch CLI subcommands to cli.py, everything else to
            # the Qt GUI (run_qt.py). Mirrors the PKGBUILD's /usr/bin/mod-manager.
            mkdir -p "$out/bin"
            makeWrapper ${pythonEnv}/bin/python3 "$out/bin/amethyst-mod-manager" \
              --add-flags "$appdir/run_qt.py" \
              --chdir "$appdir" \
              --prefix PATH : "${runtimePath}" \
              --set MOD_MANAGER_GAMES "$appdir/Games"

            runHook postInstall
          '';

          # wrapQtAppsHook re-wraps $out/bin/* with the Qt plugin path.
          dontWrapQtApps = false;

          meta = {
            description = "Linux-native mod manager for a variety of games (v2.0 Qt build from source)";
            homepage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager";
            license = pkgs.lib.licenses.gpl3Only;
            platforms = [ "x86_64-linux" ];
            mainProgram = "amethyst-mod-manager";
          };
        };
    };
}
