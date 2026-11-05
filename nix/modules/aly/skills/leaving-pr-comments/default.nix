_: let
  skillSource = import ../_lib.nix ./.;
in {
  flake.homeModules.aly = {
    home.file.".agents/skills/leaving-pr-comments".source = skillSource;
    programs.codex.skills."leaving-pr-comments" = skillSource;
    programs.opencode.skills."leaving-pr-comments" = skillSource;
    programs.crush.skills."leaving-pr-comments" = skillSource;
    programs.claude-code.skills."leaving-pr-comments" = skillSource;
  };
}
