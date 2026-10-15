_: {
  flake.homeModules.aly = _: {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;
      mutableSettings = true;
      settings = {
        permissions.defaultMode = "bypassPermissions";
        sandbox.enabled = false;
      };
    };
  };
}
