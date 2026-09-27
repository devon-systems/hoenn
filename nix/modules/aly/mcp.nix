{inputs, ...}: {
  flake.homeModules.aly = {
    lib,
    pkgs,
    ...
  }: {
    programs.mcp = {
      enable = true;

      servers = {
        nixos.command = lib.getExe pkgs.mcp-nixos;
        tg.command = lib.getExe inputs.tg.packages.${pkgs.stdenv.hostPlatform.system}.tgmcp;
      };
    };
  };
}
