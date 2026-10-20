_: {
  flake.homeModules.aly = _: {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;
      mutableSettings = true;

      settings = {
        attribution = {
          commit = "";
          pr = "";
          sessionUrl = false;
        };

        permissions.defaultMode = "bypassPermissions";
        sandbox.enabled = false;
      };
    };
  };
}
