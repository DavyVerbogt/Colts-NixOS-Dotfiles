{ ... }: {
  # Prebuilt binaries not from nixpkgs expect a standard FHS dynamic loader
  # path and library search order. nix-ld provides that shim, resolving
  # deps via NIX_LD_LIBRARY_PATH instead. Needed for the LWJGL/OpenAL/GLFW
  # native libraries that Mojang's launcher metadata ships (and that
  # Gradle's runClient/runServer tasks unpack under ForgeGradle/Loom when
  # modding) — those are built against a generic glibc, not nixpkgs, so
  # without this they fail with "error while loading shared libraries".
  flake.nixosModules.nix-ld = { pkgs, ... }: {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      libGL
      vulkan-loader
      openal
      alsa-lib
      libpulseaudio
      xorg.libX11
      xorg.libXext
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXxf86vm
      glfw
      stdenv.cc.cc.lib
    ];
  };
}
