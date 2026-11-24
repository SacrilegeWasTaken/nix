# Sapling is installed from the pinned Homebrew tap because nixpkgs has not
# packaged the current upstream release yet. Keep its configuration managed by
# Home Manager, sharing identity and signing settings with Git.
{ config, lib, pkgs, ... }:

let
  git = config.programs.git;
  saplingConfig = ''
    [ui]
    username = ${git.settings.user.name} <${git.settings.user.email}>
    merge = internal:merge3
    merge:interactive = internal:merge3

    [gpg]
    key = ${git.signing.key}
    enabled = true
  '';
in
{
  programs.sapling.enable = false;

  xdg.configFile."sapling/sapling.conf" = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    text = saplingConfig;
  };

  home.file."Library/Preferences/sapling/sapling.conf" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    text = saplingConfig;
  };
}
