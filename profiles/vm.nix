# Lightweight profile for NixOS VM (e.g. Parallels on Mac, arm64).
# Minimal system packages; Parallels-specific config lives in hosts/nixos-vm/hardware-configuration.nix.
{ config, pkgs, ... }:

{
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 3d";
  nix.optimise.automatic = true;

  # Reduced set of system packages for VM (no heavy GUI/apps)
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    neovim
    fish
    starship
    tree
    firefox
    vscode
    code-cursor
    llvm
    clang
  ];
}
