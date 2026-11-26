{
  inputs,
  self,
  ...
}: {
  flake.systemModules.rustboro = {
    nix.enable = false;

    # Ubuntu creates the account. Preserve its password database and group IDs.
    services.userborn.enable = false;
    users.groups.aly = {};
    users.users.aly = {
      isNormalUser = true;
      uid = 1000;
      group = "aly";
      home = "/home/aly";
    };

    # The activation login shell needs Ubuntu's profile tools and native Nix.
    systemd.services.home-manager-aly.path = [
      "/usr"
      "/nix/var/nix/profiles/default"
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = false;
      # Keep the ~/.nix-profile path used by Aly's login shell.
      enableLegacyProfileManagement = true;
      backupFileExtension = "before-home-manager";
      extraSpecialArgs = {inherit self;};
      users.aly.imports = [
        inputs.appherder.homeModules.appherder
        self.homeModules.aly
        self.homeModules.rustboro
      ];
    };
  };
}
