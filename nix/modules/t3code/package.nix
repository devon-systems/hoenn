{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    upstream = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code;
    t3code = upstream.override {
      t3code-unwrapped = upstream.unwrapped.overrideAttrs (previous: {
        # Connect requires this public identifier in the compiled client.
        env =
          (previous.env or {})
          // {
            T3CODE_CLERK_JWT_TEMPLATE = "t3-relay";
          };
      });
    };
  in {
    packages = {
      inherit t3code;
      t3code-desktop = t3code.desktop;
    };
  };
}
