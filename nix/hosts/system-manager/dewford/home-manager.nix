{self, ...}: {
  flake.systemModules.dewford = {
    # Ubuntu creates the account. Preserve its password database and group IDs.
    services.userborn.enable = false;
    users.groups.aly = {};
    users.users.aly = {
      isNormalUser = true;
      uid = 1000;
      group = "aly";
      home = "/home/aly";
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = false;
      # Keep the ~/.nix-profile path used by Aly's login shell.
      enableLegacyProfileManagement = true;
      backupFileExtension = "before-home-manager";
      extraSpecialArgs = {inherit self;};
      users.aly.imports = [
        self.homeModules.aly
        self.homeModules.dewford
      ];
    };
  };
}
