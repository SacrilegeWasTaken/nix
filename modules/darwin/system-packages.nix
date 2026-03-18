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
    uv
    nodejs
    starship
    hexyl
    obsidian
    nil
    nixd
    docker
    docker-compose
    telegram-desktop
    clang-tools
    claude-code
  ];
}
pin