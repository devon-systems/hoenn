{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.crush = {
      enable = true;
      enableMcpIntegration = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.crush;
    };

    xdg.configFile."crush/crushrc".text = ''
      option attribution-trailer-style none
      option attribution-generated-with false
    '';
  };
}
