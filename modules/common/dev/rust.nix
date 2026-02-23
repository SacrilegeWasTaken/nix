# Declarative Rust: rustup from nixpkgs, PATH via environment. No post-activation scripts.
{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.rustup ];

  environment.extraInit = ''
    [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
    export CARGO_HOME="$HOME/.cargo"
  '';
}
