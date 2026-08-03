# Darwin system packages. Rust/Haskell are in modules/common/dev.
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    # pipx 1.14.0 tests in test_inject.py break under the pytest shipped in the
    # current nixpkgs snapshot (parametrize splits the spec string per character);
    # drop the workaround once nixpkgs fixes the package.
    (pipx.overridePythonAttrs (old: {
      disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [ "tests/test_inject.py" ];
    }))
    ripgrep
    fd
    zig
    zls
    ncdu
    cmake
    # bazelisk resolves the Bazel version per project (.bazelversion / MODULE.bazel).
    # Expose it as `bazel` too, and skip the sha256sum helper it ships to keep it
    # out of the system PATH.
    (runCommand "bazelisk-with-bazel" { } ''
      mkdir -p $out/bin
      ln -s ${bazelisk}/bin/bazelisk $out/bin/bazelisk
      ln -s ${bazelisk}/bin/bazelisk $out/bin/bazel
    '')
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
    alacritty
    kitty
    sops
    age
    ffmpeg
    tmux
    jdk21
    yazi
    # zellij comes from home-manager (patched package, see common/home/zellij.nix)
    lazygit
  ];
}
