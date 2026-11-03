{inputs, ...}: {
  perSystem = {system, ...}: {
    packages = {
      inherit (inputs.dvnpkgs.packages.${system}) t3code t3code-desktop;
    };
  };
}
