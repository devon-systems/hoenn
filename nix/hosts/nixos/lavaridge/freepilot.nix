{inputs, ...}: {
  flake.nixosModules.lavaridge = {
    config,
    pkgs,
    ...
  }: {
    environment.systemPackages = [
      inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.freepilot
    ];

    # freepilot and ddcutil reach the BenQ RD280UG over /dev/i2c-*. The
    # seat already grants local sessions access; the group covers SSH.
    hardware.i2c.enable = true;
    users.users.aly.extraGroups = [config.hardware.i2c.group];
  };
}
