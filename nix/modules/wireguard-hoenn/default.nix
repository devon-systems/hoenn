{
  inputs,
  lib,
  ...
}: {
  options.flake.darwinModules.wireguardHoenn = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };
  config.flake = {
    darwinModules.wireguardHoenn = {
      config,
      lib,
      self,
      ...
    }: {
      # Backport nix-darwin#1738 without changing the pinned nix-darwin input.
      disabledModules = ["services/wg-quick.nix"];
      imports = [
        inputs.wg-hoenn.darwinModules.default
        (builtins.toFile "wg-quick.nix" (lib.replaceStrings
          [
            "      serviceConfig = {"
            "        ProgramArguments =\n          [ \"\${pkgs.wireguard-tools}/bin/wg-quick\" \"up\" \"\${name}\" ];\n"
          ]
          [
            "      command = \"\${pkgs.wireguard-tools}/bin/wg-quick up \${name}\";\n      serviceConfig = {"
            ""
          ]
          (builtins.readFile "${self.inputs.nix-darwin}/modules/services/wg-quick.nix")))
      ];

      sops.secrets.wireguard-hoenn-private = {
        sopsFile = self + "/secrets/wireguard-hoenn.yaml";
        key = config.wg-hoenn.nodeName;
      };
      wg-hoenn.privateKeyFile = config.sops.secrets.wireguard-hoenn-private.path;
    };
    nixosModules.wireguardHoenn = {
      config,
      self,
      ...
    }: {
      imports = [inputs.wg-hoenn.nixosModules.client];
      sops.secrets.wireguard-hoenn-private = {
        sopsFile = self + "/secrets/wireguard-hoenn.yaml";
        key = config.wg-hoenn.nodeName;
        mode = "0400";
        restartUnits = ["wireguard-hoenn.service"];
      };
      wg-hoenn.privateKeyFile = config.sops.secrets.wireguard-hoenn-private.path;
      networking.firewall.trustedInterfaces = ["hoenn"];
    };
  };
}
