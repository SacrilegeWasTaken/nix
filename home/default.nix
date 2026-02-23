# Unified home-manager entry: common modules + platform-specific (Darwin vs NixOS).
{ config, pkgs, lib, ... }:

{
  home.username = "vietnamveteran";
  home.homeDirectory = lib.mkForce (if pkgs.stdenv.isDarwin then "/Users/vietnamveteran" else "/home/vietnamveteran");
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  imports = [
    ../modules/common/home/fish.nix
    ../modules/common/home/git.nix
    ../modules/darwin/home/default.nix
    ../modules/nixos/home/default.nix
  ];
}
