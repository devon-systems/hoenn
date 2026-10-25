{inputs, ...}: {
  flake.homeModules.aly = {
    lib,
    pkgs,
    ...
  }: {
    programs.mcp = {
      enable = true;

      servers = {
        chrome-devtools = {
          command = lib.getExe inputs.mcp-servers-nix.packages.${pkgs.stdenv.hostPlatform.system}.chrome-devtools-mcp;
          args =
            [
              "--executable-path"
              (lib.getExe pkgs.google-chrome)
              "--isolated"
            ]
            ++ lib.optional pkgs.stdenv.hostPlatform.isLinux "--chrome-arg=--ozone-platform=wayland";
        };

        linear.url = "https://mcp.linear.app/mcp";
        nixos.command = lib.getExe (pkgs.mcp-nixos.override {
          # FastMCP 3 requires the MCP 1 API.
          python3Packages = pkgs.python3Packages.overrideScope (_: prev: {
            mcp = prev.mcp_1;
          });
        });
        tg.command = lib.getExe inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.tgmcp;
        todoist.url = "https://ai.todoist.net/mcp";
      };
    };
  };
}
