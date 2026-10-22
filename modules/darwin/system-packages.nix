# Darwin system packages. Rust/Haskell are in modules/common/dev.
{ config, lib, pkgs, ... }:

let
  # macOS 27 does not expose applications launched through Nix's binary
  # wrappers to Accessibility clients reliably. Keep the real executable as
  # the app-bundle entry point so AeroSpace can discover and manage its window.
  kittyForAeroSpace = pkgs.kitty.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      mv "$out/Applications/kitty.app/Contents/MacOS/.kitty-wrapped" \
        "$out/Applications/kitty.app/Contents/MacOS/kitty"
    '';
  });

  telegramDesktopForAeroSpace = pkgs.telegram-desktop.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.python3 ];
    postFixup = (old.postFixup or "") + ''
      ${pkgs.python3}/bin/python3 - "$out/Applications/Telegram.app/Contents/Info.plist" <<'PYEOF'
      import plistlib
      import sys

      plist_path = sys.argv[1]
      with open(plist_path, "rb") as plist_file:
          plist = plistlib.load(plist_file)

      plist.setdefault("LSEnvironment", {})["QT_PLUGIN_PATH"] = "${lib.makeSearchPath "lib/qt-6/plugins" [
        pkgs.qt6.qtbase
        pkgs.qt6.qtimageformats
        pkgs.qt6.qtsvg
        pkgs.qt6.qtdeclarative
      ]}"

      with open(plist_path, "wb") as plist_file:
          plistlib.dump(plist, plist_file, fmt=plistlib.FMT_BINARY)
      PYEOF
      mv "$out/Applications/Telegram.app/Contents/MacOS/.Telegram-wrapped" \
        "$out/Applications/Telegram.app/Contents/MacOS/Telegram"
    '';
  });
in

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
    buck2
    # Not from Homebrew (the formula was disabled upstream because it fails to
    # build) and not pkgs.infer, which is a source build of the whole OCaml
    # stack; see pkgs/infer.nix for the prebuilt release instead.
    (callPackage ../../pkgs/infer.nix { })
    btop
    tree
    uv
    nodejs
    pnpm
    starship
    hexyl
    obsidian
    nil
    nixd
    docker
    docker-compose
    telegramDesktopForAeroSpace
    clang-tools
    claude-code
    # Pinned ahead of nixpkgs (codex ships every other day); see pkgs/codex.nix.
    (callPackage ../../pkgs/codex.nix {})
    kittyForAeroSpace
    sops
    age
    ffmpeg
    tmux
    jdk21
    yazi
    # zellij comes from home-manager.
    lazygit
    gh
  ];
}
