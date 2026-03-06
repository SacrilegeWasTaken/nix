# Declarative Haskell: GHC, cabal-install, stack from nixpkgs; PATH for .ghcup/.cabal. No post-activation scripts.
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghc
    cabal-install
    haskell-language-server
    stack
    pkg-config
    SDL2
    glew
    freetype
  ];

  environment.extraInit = ''
    [ -d "$HOME/.cabal/bin" ] && export PATH="$HOME/.cabal/bin:$PATH"
  '';
}
