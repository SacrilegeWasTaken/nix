# NixOS laptop host. Uses profile laptop; common dev from flake.
{ config, pkgs, stateVersion, ... }:

{
  # Hardware per-machine: on each laptop run nixos-generate-config, keep /etc/nixos/hardware-configuration.nix
  imports = [
    "/etc/nixos/hardware-configuration.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/users
    ../../modules/nixos/desktop/gnome.nix
  ];

  networking.hostName = "nixos";
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = stateVersion;
}
