_: let
  skillSource = import ../_lib.nix ./.;
in {
  flake.homeModules.aly = {
    home.file.".agents/skills/writing-prs".source = skillSource;
    programs.codex.skills."writing-prs" = skillSource;
    programs.opencode.skills."writing-prs" = skillSource;
    programs.crush.skills."writing-prs" = skillSource;
    programs.claude-code.skills."writing-prs" = skillSource;
  };
}
