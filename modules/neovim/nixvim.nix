# Nixvim: custom neovim package with config. Requires specialArgs.nixvim.
{ config, pkgs, nixvim, ... }:

{
  config = {
    environment.systemPackages = let
      nixvimPkgs = nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in [
      (nixvimPkgs.makeNixvim {
        imports = [ ./config.nix ];
      })
    ];
  };
}
