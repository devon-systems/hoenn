{inputs, ...}: {
  flake.homeModules.claude-desktop = {pkgs, ...}: {
    home.packages = [inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop];
  };
}
