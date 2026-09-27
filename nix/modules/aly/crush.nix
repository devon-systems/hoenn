{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.crush = {
      enable = true;
      enableMcpIntegration = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.crush.overrideAttrs (_: {
        version = "0.96.2-symlinked-skills";
        src = inputs.crush-fork;
        vendorHash = "sha256-kGvyIpS+ZrwfOl0j1Wj/tnMEiCB6zdll0vql+35jSg4=";
        ldflags = [
          "-s"
          "-w"
          "-X=github.com/charmbracelet/crush/internal/version.Version=0.96.2-symlinked-skills"
        ];
      });
    };

    xdg.configFile."crush/crushrc".text = ''
      option attribution-trailer-style none
      option attribution-generated-with false
      option ui compact true
    '';
  };
}
