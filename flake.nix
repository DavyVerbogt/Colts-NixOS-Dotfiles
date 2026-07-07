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

    amethyst-mm = {
      url = "github:ChrisDKN/Amethyst-Mod-Manager/v2.0.0-beta.9";
      flake = false; # it's a source repo, not a flake
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
