# Homebrew taps, casks, mas. brews: juliaup added in modules/darwin/julia.nix; ghcup not needed (Haskell from nix).
{ config, pkgs, ... }:

{
  # Homebrew 4.7+ requires keyword syntax in casks (`depends_on macos: ...`).
  # Some tap revisions still ship `depends_on :macos`; normalize before bundle.
  system.activationScripts.homebrew.text = pkgs.lib.mkBefore ''
    if [ -d "/opt/homebrew/Library/Taps/homebrew/homebrew-cask/Casks" ]; then
      /usr/bin/python3 <<'PY'
from pathlib import Path

root = Path("/opt/homebrew/Library/Taps/homebrew/homebrew-cask/Casks")
for cask in root.rglob("*.rb"):
    content = cask.read_text()
    if "depends_on :macos\n" in content:
        cask.write_text(content.replace("depends_on :macos\n", ""))
PY
    fi
  '';

  homebrew = {
    enable = true;
    greedyCasks = true;
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
      # Homebrew 6 refuses formulae/casks from untrusted third-party taps.
      # These taps are pinned as flake inputs, so trusting them is declarative.
      {
        name = "nikitabobko/tap";
        clone_target = "https://github.com/nikitabobko/homebrew-tap.git";
        trusted = true;
      }
      # No clone_target here: with a custom remote, bundle records tap trust by
      # URL, which can never match this tap — nix-homebrew installs it from a
      # flake input as a remote-less store symlink, not a git clone. Without
      # clone_target, trust is recorded by tap name and matches. The tap itself
      # still comes from the flake input (see nix-homebrew.taps in flake.nix).
      {
        name = "sacrilegewastaken/homebrew-tap";
        trusted = true;
      }
    ];
    brews = [
      "bazel-remote"
      "mas"
      "swiftformat"
      "xcodes"
    ];
    casks = [
      "zen"
      # Raycast's release server rejects downloads from this network (HTTP 403),
      # so a greedy upgrade fails the whole bundle. The app updates itself
      # (auto_updates), so let brew skip its upgrades.
      { name = "raycast"; greedy = false; }
      "orbstack"
      "aerospace"
      # Pin the versioned cask: the "olovebar" latest alias points at the
      # mutable download/latest/ release asset, which isn't updated per release.
      "olovebar@0.6.0"
    ];
    masApps = {
      # "Amphetamine" = 937984704;
      # "Xcode" = 497799835;
      # "Keynote" = 409183694;
      # "Pages" = 409201541;
      # "v2RayTun" = 6476628951;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
