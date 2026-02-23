# NixOS laptop host. Uses profile laptop; common dev from flake.
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/users/vietnamveteran.nix
    ../../modules/nixos/desktop/gnome.nix
  ];

  networking.hostName = "nixos";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
}
