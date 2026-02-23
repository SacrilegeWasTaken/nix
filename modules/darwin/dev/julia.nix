# Julia on Darwin only: install via Homebrew (juliaup). No post-activation scripts.
{ config, pkgs, ... }:

{
  homebrew.brews = [ "juliaup" ];

  environment.extraInit = ''
    [ -d "$HOME/.juliaup/bin" ] && export PATH="$HOME/.juliaup/bin:$PATH"
  '';
}
