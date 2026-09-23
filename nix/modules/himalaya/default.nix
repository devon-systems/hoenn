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

      himalaya = {
        enable = true;

        settings = {
          mailbox.alias = {
            archive = "Archive";
            drafts = "Drafts";
            inbox = "INBOX";
            sent = "Sent";
            trash = "Trash";
          };

          imap = {
            server = "imaps://imap.fastmail.com:993";

            sasl.plain = {
              username = "alyraffauf@fastmail.com";
              password.command = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.fastmail.path}";
            };
          };

          smtp = {
            server = "smtps://smtp.fastmail.com:465";

            sasl.plain = {
              username = "alyraffauf@fastmail.com";
              password.command = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.fastmail.path}";
            };
          };
        };
      };
    };
  };
}
