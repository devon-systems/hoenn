_: let
  skillSource = import ../_lib.nix ./.;
in {
  flake.homeModules.aly = {
    home.file.".agents/skills/babysit-pr".source = skillSource;
    programs.codex.skills."babysit-pr" = skillSource;
    programs.opencode.skills."babysit-pr" = skillSource;
    programs.crush.skills."babysit-pr" = skillSource;
    programs.claude-code.skills."babysit-pr" = skillSource;
  };
}
