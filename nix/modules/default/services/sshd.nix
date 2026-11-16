_: {
  flake = {
    nixosModules.default = {
      services.openssh = {
        enable = true;
        settings = {
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
        };
      };
    };

    darwinModules.default = {
      services.openssh.enable = true;
    };
  };
}
