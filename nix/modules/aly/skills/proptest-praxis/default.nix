_: let
  skillSource = import ../_lib.nix ./.;
in {
  flake.homeModules.aly = {
    home.file.".agents/skills/proptest-praxis".source = skillSource;
    programs.codex.skills."proptest-praxis" = skillSource;
    programs.opencode.skills."proptest-praxis" = skillSource;
    programs.crush.skills."proptest-praxis" = skillSource;
    programs.claude-code.skills."proptest-praxis" = skillSource;
  };
}
