_: let
  builders = [
    {
      hostName = "lavaridge.narwhal-snapper.ts.net";
      systems = ["x86_64-linux"];
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
    }
    {
      hostName = "fallarbor.narwhal-snapper.ts.net";
      systems = ["aarch64-darwin"];
      maxJobs = 2;
      speedFactor = 1;
      supportedFeatures = ["benchmark" "big-parallel"];
    }
  ];
  remoteBuilders = hostName:
    map (builder:
      builder
      // {
        protocol = "ssh-ng";
        sshUser = "aly";
      })
    (builtins.filter (builder: builder.hostName != "${hostName}.narwhal-snapper.ts.net") builders);
in {
  flake.nixosModules.remoteBuilds = {config, ...}: {
    nix.distributedBuilds = true;
    nix.buildMachines = remoteBuilders config.networking.hostName;
    nix.settings.builders-use-substitutes = true;
  };
}
