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

    # No merge tool. Sapling writes the conflict into the file and stops; the
    # files are then edited by hand, in whatever editor is already open, and
    # `sl resolve --mark <file>` says each one is done.
    #
    # ":merge3" is internal -- the leading colon is what marks it as an
    # algorithm rather than a program -- so nothing is launched and nothing can
    # be waited on. It writes three sections: this side, the common ancestor,
    # and the other side. The ancestor is the half worth having: where two
    # branches edit the same lines the answer is usually "both, and here is
    # what each of them changed", and only the base shows which is which.
    #
    # This has to be named explicitly, and that is the whole bug it fixes. With
    # ui.merge unset Sapling picks from its built-in table by priority, and on
    # macOS that is filemergexcode -- Xcode's FileMerge, a GUI that opens
    # behind the terminal and holds the merge until somebody finds it. There
    # used to be a vimdiff entry here meant to prevent exactly that; it pointed
    # at ${config.home.profileDirectory}/bin/nvim, a path that has never
    # existed, because nixvim is a nix-darwin module (flake.nix imports
    # modules/neovim/nixvim.nix) and so nvim lives in the system profile. A
    # merge tool whose executable is missing is skipped *in silence*, which is
    # how a priority of 100 lost to FileMerge without a word.
    extraConfig.ui.merge = ":merge3";
  };
}
