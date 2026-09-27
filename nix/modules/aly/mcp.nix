{inputs, ...}: {
  flake.homeModules.aly = {
    lib,
    pkgs,
    ...
  }: {
    programs.mcp = {
      enable = true;
      servers.tg.command = lib.getExe inputs.tg.packages.${pkgs.stdenv.hostPlatform.system}.tgmcp;
    };
  };
}
