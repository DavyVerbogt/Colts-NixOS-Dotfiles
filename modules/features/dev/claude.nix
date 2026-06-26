{ self, inputs, ... }: {

  # Claude Desktop for Linux (k3d3/claude-desktop-linux-flake).
  # Uses the FHS-wrapped variant so MCP servers (npx, uvx, docker) work correctly.
  # Imported in hosts/ws01-nix/config.nix as: self.nixosModules.claude
  flake.nixosModules.claude = { pkgs, ... }: {
    environment.systemPackages = [
      inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-with-fhs
    ];
  };
}
