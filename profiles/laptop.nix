# Full "laptop" profile: main machine (Darwin or NixOS).
# Aggressive GC; full dev tooling is added via modules/common/dev in the flake.
{ config, lib, pkgs, ... }:

{
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 2d";
  nix.optimise.automatic = true;
}
