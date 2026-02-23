# Darwin system packages. Rust/Haskell are in modules/common/dev.
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    zig
    zls
    ncdu
    cmake
    btop
    tree
    c3c
    c3-lsp
    uv
    nodejs
    starship
    hexyl
    tmux
    obsidian
    nil
    nixd
    docker
    docker-compose
    zed-editor
  ];
}
