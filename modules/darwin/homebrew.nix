# Homebrew taps, casks, and App Store applications.
{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    greedyCasks = true;
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
      {
        name = "nikitabobko/tap";
        clone_target = "https://github.com/nikitabobko/homebrew-tap.git";
        trusted = true;
      }
      {
        name = "sacrilegewastaken/homebrew-tap";
        trusted = true;
      }
    ];
    brews = [
      "bazel-remote"
      "dotslash"
      "mas"
      # From Homebrew rather than nixpkgs: the nixpkgs build is not in the
      # binary cache for aarch64-darwin, so every bump means compiling mise
      # from source, while homebrew-core ships an arm64 bottle.
      "mise"
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
