# Nixvim module integration for nix-darwin.
{ ... }:

{
  programs.nixvim = {
    enable = true;
    imports = [ ./config.nix ];
  };
}
