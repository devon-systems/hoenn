{inputs, ...}: {
  flake.homeModules.t3code = {pkgs, ...}: {
    programs.t3code = {
      enable = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop;
      mutableClientSettings = true;
      mutableKeybindings = true;
      mutableUserSettings = true;
    };
  };
}
