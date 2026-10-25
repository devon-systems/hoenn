{inputs, ...}: {
  flake.nixosModules.nixos = {
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.lanzaboote.nixosModules.lanzaboote];

    boot = {
      lanzaboote = {
        enable = true;
        autoEnrollKeys.enable = true;
        autoGenerateKeys.enable = true;
        configurationLimit = 10;
        pkiBundle = lib.mkDefault "/var/lib/sbctl";
      };

      loader.systemd-boot.enable = lib.mkForce false;
    };

    environment.systemPackages = [pkgs.sbctl];
  };
}
