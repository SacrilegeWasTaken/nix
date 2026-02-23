# Declarative Haskell: GHC, cabal-install, stack from nixpkgs; PATH for .ghcup/.cabal. No post-activation scripts.
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghc
    cabal-install
    stack
  ];

  environment.extraInit = ''
    [ -d "$HOME/.ghcup/bin" ] && export PATH="$HOME/.ghcup/bin:$PATH"
    [ -d "$HOME/.cabal/bin" ] && export PATH="$HOME/.cabal/bin:$PATH"
  '';
}
