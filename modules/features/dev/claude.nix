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
  flake.nixosModules.claude = { pkgs, ... }: {
    environment.systemPackages = [
      inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
