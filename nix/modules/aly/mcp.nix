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
          command = lib.getExe' pkgs.nodejs "npx";
          args = [
            "-y"
            "chrome-devtools-mcp@latest"
            "--isolated"
          ];
        };
        nixos.command = lib.getExe pkgs.mcp-nixos;
        tg.command = lib.getExe inputs.tg.packages.${pkgs.stdenv.hostPlatform.system}.tgmcp;
      };
    };
  };
}
