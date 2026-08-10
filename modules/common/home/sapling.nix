# Common home-manager Sapling (sl) config. Identity and the OpenPGP signing key
# are taken from git.nix so both VCS tools sign with the same key; the key
# itself is provisioned into the keyring by the sops activation script there.
{ config, ... }:

let
  git = config.programs.git;
in
{
  programs.sapling = {
    enable = true;

    # Sapling matches the signing key against ui.username, which it composes
    # from these two; they must equal the uid on the GPG key.
    userName = git.settings.user.name;
    userEmail = git.settings.user.email;

    # Sapling has no per-commit -S flag: signing is a repository-wide setting,
    # so declaring the key here signs every commit. The legacy [gpg] section is
    # used rather than the newer [signing] one because [signing] landed after
    # the Sapling release packaged in nixpkgs (0.2.20250521) and is silently
    # ignored by it, while [gpg] is honoured by both.
    extraConfig.gpg = {
      key = git.signing.key;
      enabled = true;
    };
  };
}
