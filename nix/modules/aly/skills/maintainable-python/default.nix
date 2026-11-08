_: let
  skillSource = import ../_lib.nix ./.;
in {
  flake.homeModules.aly = {
    home.file.".agents/skills/maintainable-python".source = skillSource;
    programs.codex.skills."maintainable-python" = skillSource;
    programs.opencode.skills."maintainable-python" = skillSource;
    programs.crush.skills."maintainable-python" = skillSource;
    programs.claude-code.skills."maintainable-python" = skillSource;
  };
}
