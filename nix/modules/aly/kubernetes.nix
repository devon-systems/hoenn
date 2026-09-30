{inputs, ...}: {
  flake.homeModules.aly = {
    config,
    pkgs,
    self,
    ...
  }: {
    imports = [inputs.sops-nix.homeManagerModules.sops];

    sops = {
      age.sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];

      secrets = {
        kube-sinnoh = {
          key = "";
          sopsFile = self + "/secrets/kube-sinnoh.yaml";
        };

        kube-johto = {
          key = "";
          sopsFile = self + "/secrets/kube-johto.yaml";
        };
      };
    };

    home.packages = [pkgs.kubectl];

    programs.kubeswitch = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        kind = "SwitchConfig";
        version = "v1alpha1";
        kubeconfigStores = [
          {
            kind = "filesystem";
            kubeconfigName = "*";
            showPrefix = false;
            paths = [
              config.sops.secrets.kube-sinnoh.path
              config.sops.secrets.kube-johto.path
            ];
          }
        ];
      };
    };
  };
}
