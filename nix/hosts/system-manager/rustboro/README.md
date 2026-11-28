# Rustboro

Rustboro runs Ubuntu on x86_64. Hoenn manages its system configuration through
the `systemConfigs.rustboro` flake output. Ubuntu owns the `aly` account, and
Home Manager applies the shared `aly` profile and enables the appherder user
service with automatic upgrades.
