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
          args = [
            "--executable-path"
            (lib.getExe pkgs.google-chrome)
            "--isolated"
          ];
        };
        nixos.command = lib.getExe pkgs.mcp-nixos;
        tg.command = lib.getExe inputs.tg.packages.${pkgs.stdenv.hostPlatform.system}.tgmcp;
      };
    };
  };
}
