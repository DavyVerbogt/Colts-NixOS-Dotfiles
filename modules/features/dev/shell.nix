{ ... }: {
  flake.nixosModules.shell = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      tmux # terminal multiplexer
      ripgrep # fast grep (rg)
      fd # fast find
      bat # cat with syntax highlighting
      eza # modern ls
      fzf # fuzzy finder
      jq # json processor
      btop # resource monitor
      htop # process monitor
      tree # directory tree
      wget # downloader
      curl # http client
      unzip # archive extraction
    ];
  };
}
