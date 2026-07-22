{ self, inputs, ... }: {

  # Claude Desktop for Linux (patrickjaja/claude-desktop-bin).
  # Patches Anthropic's actual official Linux binary (downloaded directly
  # from Anthropic during build) with 40+ Linux-compat patches, including
  # fix_browse_files_linux.nim (file-open dialog support). Replaces the
  # earlier k3d3/claude-desktop-linux-flake package, which reimplemented the
  # native module from scratch and was missing the getAppInfoForFile
  # binding — that was the cause of the freeze-on-file-open bug.
  # No FHS/bubblewrap sandbox needed here; MCP servers work directly, and
  # third-party MCP servers requiring system Node.js just need `nodejs`
  # available on PATH (not included here — add it if/when needed).
  # Imported in hosts/ws01-nix/config.nix as: self.nixosModules.claude
  #
  # Cowork device bridge (folder access from cloud sessions):
  # Cowork mounts trusted folders into a local QEMU microVM via virtiofsd.
  # Upstream Claude Desktop only probes /usr/libexec/virtiofsd and
  # /usr/bin/virtiofsd (bundled fallback is gated to Ubuntu 22 only) —
  # see anthropics/claude-code#74605. claude-desktop-bin PR #178
  # (merged 2026-07-02) adds /run/current-system/sw/bin/virtiofsd as a
  # probe candidate for NixOS, which is why pkgs.virtiofsd must be in
  # systemPackages here. Requires the claude-desktop input to be at or
  # past that PR — run `nix flake update claude-desktop` if the Cowork
  # tab still claims QEMU is missing. QEMU itself is wrapped into the
  # package by the flake, so it isn't added here.
  # vhost_vsock is the host<->VM channel the bridge talks over; the kvm
  # group grants /dev/kvm access. First VM start downloads a workspace
  # image (~25 GB free disk recommended, 8 GB RAM minimum).
  flake.nixosModules.claude = { pkgs, ... }: {
    imports = with self.nixosModules; [ cowork ];
    environment.systemPackages = [
      inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.virtiofsd # /run/current-system/sw/bin/virtiofsd — probed by the Cowork VM launcher
    ];

    boot.kernelModules = [ "vhost_vsock" ];

    users.users.colt.extraGroups = [ "kvm" ];
  };
}
