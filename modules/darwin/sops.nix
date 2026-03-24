# SOPS-nix: encrypted secrets decrypted at activation time.
# Age key lives at ~/.config/sops/age/keys.txt (generated once via `make sops-init`).
# Secrets file: secrets/default.yaml (encrypted in git, decrypted to /run/secrets/).
#
# If secrets/default.yaml doesn't exist yet, this module is a no-op.
# Run `make sops-init` to bootstrap, then `make rebuild`.
{ config, pkgs, lib, username, ... }:

let
  secretsFile = ../../secrets/default.yaml;
  hasSecrets = builtins.pathExists secretsFile;
in
{
  sops = lib.mkIf hasSecrets {
    defaultSopsFile = secretsFile;
    age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";

    secrets = {
      tavily-api-key = { };
    };
  };
}
