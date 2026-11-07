_: let
  skillSource = import ../_lib.nix ./.;
in {
  flake.homeModules.aly = {
    home.file.".agents/skills/walkthrough-change".source = skillSource;
    programs.codex.skills."walkthrough-change" = skillSource;
    programs.opencode.skills."walkthrough-change" = skillSource;
    programs.crush.skills."walkthrough-change" = skillSource;
    programs.claude-code.skills."walkthrough-change" = skillSource;
  };
}
