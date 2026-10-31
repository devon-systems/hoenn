_: let
  module = {
    programs.fish.enable = true;
  };
in {
  flake = {
    nixosModules.aly = module;
    darwinModules.aly = module;

    homeModules.aly = {
      programs.fish = {
        enable = true;

        shellAliases = {
          grep = "grep --color=auto";
        };

        functions = {
          fish_greeting = "";

          mkcd = {
            description = "Create a directory and enter it";

            body = ''
              if test (count $argv) -ne 1
                echo 'usage: mkcd DIRECTORY' >&2
                return 2
              end

              mkdir -p -- $argv[1]; and cd -- $argv[1]
            '';
          };
        };

        interactiveShellInit = ''
          if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
          end

          set -l homebrew_prefix
          if test -x /home/linuxbrew/.linuxbrew/bin/brew
            set homebrew_prefix /home/linuxbrew/.linuxbrew
          else if test -x /opt/homebrew/bin/brew
            set homebrew_prefix /opt/homebrew
          else if test -x /usr/local/bin/brew
            set homebrew_prefix /usr/local
          end

          if test -n "$homebrew_prefix"
            eval ($homebrew_prefix/bin/brew shellenv)

            for uutils_dir in \
              "$homebrew_prefix/opt/uutils-coreutils/libexec/uubin" \
              "$homebrew_prefix/opt/uutils-diffutils/libexec/uubin" \
              "$homebrew_prefix/opt/uutils-findutils/libexec/uubin"
              test -d "$uutils_dir"; and fish_add_path --path --prepend --move "$uutils_dir"
            end
          end

          for path_dir in \
            "$HOME/.nix-profile/bin" \
            "$HOME/go/bin" \
            "$HOME/.local/bin" \
            "$HOME/bin" \
            "$HOME/.bun/bin" \
            "$HOME/.cargo/bin" \
            "$HOME/.local/share/pnpm" \
            "$HOME/.deno/bin" \
            "$HOME/.volta/bin" \
            "$HOME/.npm/bin" \
            "$HOME/.npm-global/bin"
            test -d "$path_dir"; and fish_add_path --path --prepend --move "$path_dir"
          end

          if test "$PWD" = "/var/home/aly"
            builtin cd "$HOME"
          end
        '';
      };

      programs.man.generateCaches = false;
    };
  };
}
