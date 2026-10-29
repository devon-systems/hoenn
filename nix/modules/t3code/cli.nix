{inputs, ...}: {
  flake.homeModules.t3codeCli = {pkgs, ...}: {
    home.packages = [inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code];
  };
}
