_: let
  domain = "narwhal-snapper.ts.net";
  builders = [
    {
      name = "lavaridge";
      systems = ["x86_64-linux"];
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
    }
    {
      name = "fallarbor";
      systems = ["aarch64-darwin"];
      maxJobs = 2;
      speedFactor = 1;
      supportedFeatures = ["benchmark" "big-parallel"];
    }
  ];
  remoteBuilders = hostName: builtins.filter (builder: builder.name != hostName) builders;
in {
  flake.nixosModules.remoteBuilds = {
    config,
    self,
    ...
  }: let
    remote = remoteBuilders config.networking.hostName;
  in {
    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;

    nix.buildMachines = map (builder:
      removeAttrs builder ["name"]
      // {
        hostName = "${builder.name}.${domain}";
        protocol = "ssh-ng";
        sshUser = "aly";
      })
    remote;

    # The Nix daemon connects as root, which cannot accept host keys interactively.
    programs.ssh.knownHosts = builtins.listToAttrs (map (builder: {
        name = "${builder.name}.${domain}";
        value.publicKeyFile = self + "/keys/root_${builder.name}.pub";
      })
      remote);
  };
}
