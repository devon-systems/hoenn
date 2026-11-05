_: let
  skillSource = import ../_lib.nix ./.;
in {
  flake.homeModules.aly = {
    home.file.".agents/skills/justifiable-tests".source = skillSource;
    programs.codex.skills."justifiable-tests" = skillSource;
    programs.opencode.skills."justifiable-tests" = skillSource;
    programs.crush.skills."justifiable-tests" = skillSource;
    programs.claude-code.skills."justifiable-tests" = skillSource;
  };
}
