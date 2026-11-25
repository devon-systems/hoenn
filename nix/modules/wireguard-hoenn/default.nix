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
      self,
      ...
    }: {
      imports = [inputs.wg-hoenn.darwinModules.default];

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
