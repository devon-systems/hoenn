{lib, ...}: let
  subnet = "10.254.1.0/24";
  resolver = "10.254.1.1";

  peer = {
    allowedIPs = [subnet];
    endpoint = "40.160.83.152:51821";
    persistentKeepalive = 25;
    publicKey = "vinYIK2laJ19yVMlw6iB5lb9+wY8ZBrM+Y4nrBmMxxQ=";
  };

  nodeAddresses = {
    mauville = "10.254.1.2";
    rustboro = "10.254.1.3";
    sootopolis = "10.254.1.4";
    fallarbor = "10.254.1.6";
    pacifidlog = "10.254.1.7";
    petalburg = "10.254.1.8";
    lilycove = "10.254.1.9";
  };
in {
  options.flake.darwinModules.wireguardHoenn = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake = {
    darwinModules.wireguardHoenn = {
      config,
      lib,
      pkgs,
      self,
      ...
    }: let
      privateKey = config.sops.secrets.wireguard-hoenn-private.path;
    in {
      environment.etc."resolver/hoenn".text = "nameserver ${resolver}";

      sops.secrets.wireguard-hoenn-private = {
        sopsFile = self + "/secrets/wireguard-hoenn.yaml";
        key = "fortree";
      };

      networking.wg-quick.interfaces.hoenn = {
        address = ["10.254.1.5/24"];
        privateKeyFile = privateKey;
        preUp = ''
          while [ ! -r ${privateKey} ]; do
            /bin/sleep 1
          done
        '';

        peers = [peer];
      };

      # Backport nix-darwin#1738 so launchd waits for the Nix store to mount.
      launchd.daemons.wg-quick-hoenn.serviceConfig.ProgramArguments = lib.mkForce [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && exec ${pkgs.wireguard-tools}/bin/wg-quick up hoenn"
      ];
    };

    nixosModules.wireguardHoenn = {
      config,
      pkgs,
      self,
      ...
    }: let
      nodeAddress = nodeAddresses.${config.networking.hostName};
      privateKey = config.sops.secrets.wireguard-hoenn-private.path;
    in {
      sops.secrets.wireguard-hoenn-private = {
        sopsFile = self + "/secrets/wireguard-hoenn.yaml";
        key = config.networking.hostName;
        mode = "0400";
      };

      networking = {
        firewall.trustedInterfaces = ["hoenn"];

        wireguard.interfaces.hoenn = {
          ips = ["${nodeAddress}/24"];
          privateKeyFile = privateKey;
          postSetup = ''
            ${pkgs.systemd}/bin/resolvectl dns hoenn ${resolver}
            ${pkgs.systemd}/bin/resolvectl domain hoenn ~hoenn
            ${pkgs.systemd}/bin/resolvectl default-route hoenn false
          '';

          peers = [peer];
        };
      };

      services.resolved.enable = true;

      systemd.services.wireguard-hoenn.after = ["systemd-resolved.service"];
    };
  };
}
