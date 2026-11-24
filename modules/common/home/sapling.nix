# Sapling is installed from the pinned Homebrew tap because nixpkgs has not
# packaged the current upstream release yet. Keep its configuration managed by
# Home Manager, sharing identity and signing settings with Git.
{ config, ... }:

let
  git = config.programs.git;
in
{
  programs.sapling.enable = false;

  xdg.configFile."sapling/sapling.conf".text = ''
    [ui]
    username = ${git.settings.user.name} <${git.settings.user.email}>
    merge = internal:merge3
    merge:interactive = internal:merge3

    [gpg]
    key = ${git.signing.key}
    enabled = true
  '';
}
