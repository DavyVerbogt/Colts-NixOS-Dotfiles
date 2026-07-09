{ ... }: {
  # Deliberately a devShell, not system-wide JDK installs — three JDKs
  # fighting over JAVA_HOME/PATH at the system level is worse than scoping
  # this per mod project. Enter with `nix develop ~/Documents/NixOS#minecraft-modding`,
  # or a per-project .envrc with `use flake ~/Documents/NixOS#minecraft-modding`
  # (dev/direnv.nix already enables direnv).
  perSystem = { pkgs, ... }: {
    devShells.minecraft-modding = pkgs.mkShell {
      packages = with pkgs; [
        jdk8   # legacy Forge, 1.12 and earlier
        jdk17  # 1.17-1.20.4
        jdk21  # 1.20.5+
        gradle
      ];
      shellHook = ''
        export JAVA8_HOME=${pkgs.jdk8}/lib/openjdk
        export JAVA17_HOME=${pkgs.jdk17}/lib/openjdk
        export JAVA21_HOME=${pkgs.jdk21}/lib/openjdk
        echo "Minecraft modding shell — JDK 8/17/21 + gradle on PATH."
        echo "Legacy Forge (<=1.12): ./gradlew --java-home \$JAVA8_HOME"
        echo "1.17-1.20.4:          ./gradlew --java-home \$JAVA17_HOME"
        echo "1.20.5+:               ./gradlew --java-home \$JAVA21_HOME"
      '';
    };
  };
}
