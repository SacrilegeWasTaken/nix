# Unified home-manager entry: common modules + platform-specific (Darwin vs NixOS).
{ config, pkgs, lib, stateVersion, username, ... }:

{
  home.username = username;
  home.homeDirectory = lib.mkForce (if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}");
  home.stateVersion = stateVersion;
  programs.home-manager.enable = true;

  imports = [
    ../modules/common/home/fish.nix
    ../modules/common/home/git.nix
    ../modules/darwin/home/default.nix
    ../modules/nixos/home/default.nix
  ];
  # dotfiles.nix is imported from the flake (./modules/common/home/dotfiles.nix)
}
