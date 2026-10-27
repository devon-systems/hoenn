_: let
  alyKeyFiles = lib: self: let
    keysDirectory = self + "/keys";
  in
    lib.pipe (builtins.readDir keysDirectory) [
      builtins.attrNames
      (lib.filter (file: lib.hasPrefix "aly_" file && lib.hasSuffix ".pub" file))
      (lib.map (file: "${keysDirectory}/${file}"))
    ];
  module = {
    lib,
    self,
    ...
  }: {
    users.users.root.openssh.authorizedKeys.keyFiles = alyKeyFiles lib self;
  };
in {
  flake = {
    nixosModules.default = module;
    darwinModules.default = module;
  };
}
