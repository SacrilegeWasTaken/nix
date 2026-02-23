# NixOS VM host (Parallels, arm64). Uses profile vm (lightweight).
# Imports modules/nixos/* when they exist (see nixos-hosts todo).
{ config, pkgs, stateVersion, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos-vm";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  programs.fish.enable = true;
  users.users.vietnamveteran = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  users.defaultUserShell = pkgs.fish;

  system.stateVersion = stateVersion;
}
