# Rustup is installed declaratively. Project-specific toolchains, targets, and
# Cargo tools remain explicit user actions rather than rebuild side effects.
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.rustup ];
}
