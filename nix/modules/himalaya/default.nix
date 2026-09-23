{inputs, ...}: {
  flake.homeModules.himalaya = {
    config,
    pkgs,
    self,
    ...
  }: let
    passwordCommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.fastmail.path}";
  in {
    imports = [inputs.sops-nix.homeManagerModules.sops];

    home.packages = [pkgs.himalaya];

    sops = {
      age.sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];

      secrets.fastmail = {
        sopsFile = self + "/secrets/aly-himalaya.yaml";
      };
    };

    xdg.configFile."himalaya/config.toml".source = (pkgs.formats.toml {}).generate "himalaya-config.toml" {
      accounts.fastmail = {
        default = true;
        email = "alyraffauf@fastmail.com";
        display-name = "Aly Raffauf";

        imap = {
          server = "imaps://imap.fastmail.com:993";

          sasl.plain = {
            username = "alyraffauf@fastmail.com";
            password.command = passwordCommand;
          };
        };

        smtp = {
          server = "smtps://smtp.fastmail.com:465";

          sasl.plain = {
            username = "alyraffauf@fastmail.com";
            password.command = passwordCommand;
          };
        };
      };
    };
  };
}
