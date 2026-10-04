_: {
  flake.homeModules.zed-editor = {pkgs, ...}: {
    programs.zed-editor = {
      enable = true;
      enableMcpIntegration = true;
      installRemoteServer = true;
      mutableUserDebug = true;
      mutableUserKeymaps = true;
      mutableUserSettings = true;
      mutableUserTasks = true;

      userKeymaps = [
        {
          context = "Workspace";
          bindings = {
            cmd-p = "command_palette::Toggle";
            cmd-shift-p = "file_finder::Toggle";
            ctrl-p = "command_palette::Toggle";
            ctrl-shift-p = "file_finder::Toggle";
          };
        }
      ];

      userSettings = {
        agent = {
          auto_compact.threshold = "70%";
          commit_message_instructions = "Follow the repo's existing commit message scheme. Limit message to one sentence. All lower case, prefix with location/feature affected by the change. Be curt yet descriptive.";

          commit_message_model = {
            model = "deepseek/deepseek-v4-flash";
            provider = "openrouter";
          };

          default_profile = "write";
          dock = "left";
          expand_edit_card = false;
          expand_terminal_card = false;
          model_parameters = [];
          play_sound_when_agent_done = "never";
          sandbox_permissions.allow_all_hosts = true;
          show_turn_stats = false;
          single_file_review = true;
          thinking_display = "always_collapsed";
          tool_permissions.default = "allow";
        };

        allow_rewrap = "anywhere";
        auto_indent_on_paste = true;
        auto_install_extensions.catppuccin = true;
        autosave.after_delay.milliseconds = 1000;
        bottom_dock_layout = "left_aligned";
        buffer_font_family = "CaskaydiaCove Nerd Font";
        buffer_line_height = "standard";
        cli_default_open_behavior = "new_window";
        collaboration_panel.button = false;
        debugger.button = false;
        default_open_behavior = "new_window";
        diagnostics.button = false;
        edit_predictions.mode = "subtle";
        git.inline_blame.show_commit_summary = false;

        git_panel = {
          default_width = 240;
          dock = "right";
          tree_view = true;
        };

        icon_theme = {
          dark = "Zed (Default)";
          light = "Zed (Default)";
          mode = "dark";
        };

        languages.Python.language_servers = ["ty" "ruff"];
        lsp.gopls.initialization_options.directoryFilters = ["-vendor"];
        minimap.show = "auto";
        outline_panel.default_width = 240;
        prettier.allowed = true;
        preferred_line_length = 80;

        project_panel = {
          default_width = 240;
          dock = "right";
          entry_spacing = "standard";
          hide_gitignore = false;
          hide_root = false;
        };

        proxy = "";
        search.case_sensitive = false;
        semantic_tokens = "combined";
        session.trust_all_worktrees = true;
        soft_wrap = "bounded";

        tab_bar.show_pinned_tabs_in_separate_row = false;
        tabs.git_status = true;

        terminal = {
          font_family = "CaskaydiaCove Nerd Font";
          scrollbar.show = "auto";
          shell = "system";
          toolbar.breadcrumbs = false;
        };

        theme = {
          dark = "Catppuccin Frappé - No Italics";
          light = "One Light";
          mode = "dark";
        };

        theme_overrides."Catppuccin Frappé - No Italics" = {
          "background.appearance" =
            if pkgs.stdenv.hostPlatform.isDarwin
            then "blurred"
            else "transparent";
          "background" = "#383c5200";
          "surface.background" = "#292c3ccc";
          "elevated_surface.background" = "#292c3ccc";
          "element.background" = "#232634cc";
          "editor.background" = "#303446cc";
          "editor.gutter.background" = "#303446cc";
          "editor.subheader.background" = "#292c3ccc";
          "terminal.background" = "#303446cc";
          "terminal.ansi.background" = "#303446cc";
          "panel.background" = "#292c3ccc";
          "panel.overlay_background" = "#292c3ccc";
          "scrollbar.track.background" = "#23263400";
          "hidden.background" = "#292c3ccc";
          "hint.background" = "#292c3ccc";
          "predictive.background" = "#292c3ccc";
          "status_bar.background" = "#232634cc";
          "title_bar.background" = "#232634cc";
          "title_bar.inactive_background" = "#2a2e3ecc";
          "toolbar.background" = "#303446cc";
          "tab_bar.background" = "#232634cc";
          "tab.active_background" = "#303446cc";
          "tab.inactive_background" = "#1d202bcc";
        };

        title_bar = {
          button_layout = "platform_default";
          show_branch_status_icon = true;
          show_menus = false;
        };

        use_on_type_format = true;
        use_smartcase_search = true;
        which_key.enabled = true;
        wrap_guides = [80];
      };
    };
  };
}
