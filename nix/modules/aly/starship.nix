_: {
  flake.homeModules.aly = {
    programs.starship = {
      enable = true;

      settings = {
        add_newline = true;
        aws.symbol = "  ";
        buf.symbol = " ";
        c.symbol = " ";

        character = {
          error_symbol = "[✗](bold red) ";
          success_symbol = "[➜](bold green) ";
        };

        cmake.symbol = " ";
        cmd_duration.disabled = true;
        conda.symbol = " ";
        crystal.symbol = " ";
        custom.reboot = {
          when = ''
            test -d /run/booted-system || exit 1
            for component in kernel kernel-modules initrd; do
              booted=$(readlink -f "/run/booted-system/$component")
              current=$(readlink -f "/run/current-system/$component")
              if [ "$booted" != "$current" ]; then
                exit 0
              fi
            done
            exit 1
          '';
          shell = ["sh"];
          symbol = "↻ reboot";
          style = "bold red";
          format = "[$symbol]($style) ";
        };
        dart.symbol = " ";

        directory = {
          format = "[$path](bold blue) ";
          read_only = " 󰌾";
          truncate_to_repo = false;
        };

        direnv = {
          disabled = false;
          format = "[$symbol$loaded]($style) ";
          symbol = "direnv ";
        };

        docker_context.symbol = " ";
        elixir.symbol = " ";
        elm.symbol = " ";
        fennel.symbol = " ";
        fossil_branch.symbol = " ";

        git_branch = {
          format = "[$symbol$branch(:$remote_branch)]($style) ";
          symbol = " ";
        };

        git_commit.tag_symbol = "  ";

        git_status = {
          ahead = "⇡$count";
          behind = "⇣$count";
          conflicted = "=";
          deleted = "✘";
          diverged = "⇕⇡$ahead_count⇣$behind_count";
          format = "([$all_status$ahead_behind]($style) )";
          modified = "!";
          renamed = "»";
          staged = "+";
          untracked = "?";
        };

        golang.symbol = " ";
        gradle.symbol = " ";
        guix_shell.symbol = " ";
        haskell.symbol = " ";
        haxe.symbol = " ";
        hg_branch.symbol = " ";

        hostname = {
          disabled = false;
          format = "@[$hostname](bold green) ";
          ssh_only = false;
          ssh_symbol = " ";
        };

        java.symbol = " ";
        julia.symbol = " ";
        kotlin.symbol = " ";
        line_break.disabled = false;
        lua.symbol = " ";
        memory_usage.symbol = "󰍛 ";
        meson.symbol = "󰔷 ";
        nim.symbol = "󰆥 ";
        nix_shell.symbol = " ";
        nodejs.symbol = " ";
        ocaml.symbol = " ";

        os.symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CachyOS = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NixOS = " ";
          NetBSD = " ";
          Nobara = " ";
          OpenBSD = "󰈺 ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          RedHatEnterprise = " ";
          Redhat = " ";
          Redox = "󰀘 ";
          RockyLinux = " ";
          SUSE = " ";
          Solus = "󰠳 ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
          openSUSE = " ";
        };

        package.symbol = "󰏗 ";
        perl.symbol = " ";
        php.symbol = " ";
        pijul_channel.symbol = " ";
        python.symbol = " ";
        rlang.symbol = "󰟔 ";
        ruby.symbol = " ";
        rust.symbol = "󱘗 ";
        scala.symbol = " ";
        swift.symbol = " ";

        username = {
          disabled = false;
          format = "[$user]($style)";
          show_always = true;
          style_root = "bold red";
          style_user = "bold yellow";
        };

        zig.symbol = " ";
      };
    };
  };
}
