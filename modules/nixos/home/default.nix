# NixOS-specific home-manager config (Wayland/WM, Linux paths, etc.).
{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (!pkgs.stdenv.isDarwin) {
    # Extend as needed (e.g. hyprland in modules/nixos/home/hyprland.nix)
  };
}
