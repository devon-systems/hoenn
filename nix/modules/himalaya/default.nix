{inputs, ...}: {
  flake.homeModules.himalaya = {
    config,
    pkgs,
    self,
    ...
  }: {
    imports = [inputs.sops-nix.homeManagerModules.sops];

    sops = {
      age.sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];

      secrets.fastmail = {
        sopsFile = self + "/secrets/aly-himalaya.yaml";
      };
    };

    programs.himalaya.enable = true;

    accounts.email.accounts.fastmail = {
      address = "alyraffauf@fastmail.com";
      flavor = "fastmail.com";
      passwordCommand = ["${pkgs.coreutils}/bin/cat" config.sops.secrets.fastmail.path];
      primary = true;
      realName = "Aly Raffauf";

      himalaya.enable = true;
    };
  };
}
