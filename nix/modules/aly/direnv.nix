_: {
  flake.homeModules.aly = {config, ...}: {
    programs.direnv = {
      enable = true;

      config = {
        global = {
          log_filter = "^$";
          log_format = "-";
        };
      };

      mise.enable = config.programs.mise.enable;
      nix-direnv.enable = true;
      silent = true;

      stdlib = ''
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        declare -A direnv_layout_dirs

        direnv_layout_dir() {
          echo "''${direnv_layout_dirs[$PWD]:=$(
            echo -n "$XDG_CACHE_HOME"/direnv/layouts/
            echo -n "$PWD" | sha1sum | cut -d ' ' -f 1
          )}"
        }

        if [[ -f "$XDG_CONFIG_HOME/direnv/lib/hm-nix-direnv.sh" ]]; then
          source "$XDG_CONFIG_HOME/direnv/lib/hm-nix-direnv.sh"
        fi
      '';
    };
  };
}
