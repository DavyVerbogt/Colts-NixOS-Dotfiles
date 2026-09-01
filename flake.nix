{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    claude-desktop = {
      url = "github:patrickjaja/claude-desktop-bin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:youwen5/zen-browser-flake";
    niri-session-manager.url = "github:MTeaHead/niri-session-manager";
    nirimation = {
      url = "github:Xansidev/nirimation";
      flake = false; # it's not a flake, just files
    };
    qylock.url = "github:Darkkal44/qylock";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    amethyst-mm = {
      # Pinned by commit, not by tag. Upstream deletes/re-points its beta tags
      # (v2.0.0-beta.9 vanished, breaking `nix flake update` with a GitHub 422),
      # and a tag is a mutable ref so it was never a real pin. A rev is immutable
      # and GitHub still serves archive/<sha>.tar.gz for unreferenced commits.
      # Bump = edit this rev; `nix flake update` is a no-op for this input.
      url = "github:ChrisDKN/Amethyst-Mod-Manager/9727e79c3326abb3724c7db7b08d855e9e937b8d"; # was tag v2.0.0-beta.9
      flake = false; # it's a source repo, not a flake
    };
    claude-cowork-service = {
      url = "github:patrickjaja/claude-cowork-service";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
