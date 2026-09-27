_: {
  flake.homeModules.vscode = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [alejandra nixd];

    programs.vscode = {
      enable = true;
      mutableExtensionsDir = true;

      profiles.default = {
        enableMcpIntegration = true;
        mutableUserSettings = true;
        enableUpdateCheck = false;

        extensions = with pkgs; [
          # vscode-extensions.catppuccin.catppuccin-vsc
          # vscode-extensions.catppuccin.catppuccin-vsc-icons
          vscode-extensions.jnoortheen.nix-ide
          vscode-extensions.mkhl.direnv
          vscode-extensions.ms-vscode-remote.remote-ssh
        ];

        userSettings = {
          "catppuccin.italicComments" = false;
          "catppuccin.italicKeywords" = false;
          "chat.agent.enabled" = true;
          "chat.byokUtilityModelDefault" = "mainAgent";
          "chat.disableAIFeatures" = false;
          "chat.editor.fontSize" = 15;
          "chat.fontSize" = 15;
          "chat.viewSessions.orientation" = "stacked";
          "editor.fontFamily" = "'CaskaydiaCove Nerd Font', Menlo, Monaco, 'Courier New', monospace";
          "editor.fontSize" = 14;
          "editor.formatOnPaste" = true;
          "editor.formatOnSave" = true;
          "editor.minimap.size" = "fill";
          "editor.tabCompletion" = "on";
          "editor.wordWrap" = "wordWrapColumn";
          "files.autoSave" = "afterDelay";
          "files.autoSaveDelay" = 500;
          "files.autoSaveWorkspaceFilesOnly" = true;
          "files.trimFinalNewlines" = true;
          "files.trimTrailingWhitespace" = true;
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
          "git.openRepositoryInParentFolders" = "always";
          "github.copilot.completions.chat.enabled" = true;
          "github.copilot.nextEditSuggestions.enabled" = true;
          "terminal.integrated.fontLigatures.enabled" = true;
          "workbench.activityBar.compact" = true;
          "workbench.browser.searchEngine" = "duckduckgo";
          "workbench.colorTheme" = "Catppuccin Frappé";
          "workbench.editor.editorActionsLocation" = "titleBar";
          "workbench.iconTheme" = "catppuccin-frappe";
          "catppuccin.accentColor" = "pink";
          "catppuccin-icons.monochrome" = true;
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";
          "nix.formatterPath" = lib.getExe pkgs.alejandra;
          "nix.serverSettings" = {
            nixd.formatting.command = [(lib.getExe pkgs.alejandra)];
          };
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
          };
        };
      };
    };
  };
}
