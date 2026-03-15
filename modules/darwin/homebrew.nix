# Homebrew taps, casks, mas. brews: juliaup added in modules/darwin/julia.nix; ghcup not needed (Haskell from nix).
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
      }
      {
        name = "sacrilegewastaken/homebrew-tap";
        clone_target = "https://codeberg.org/sacrilegewastaken/tap.git";
      }
    ];
    brews = [
      "mas"
      "swiftformat"
      "xcodes"
    ];
    casks = [
      "discord"
      "cursor"
      "zen"
      "raycast"
      "docker-desktop"
      "visual-studio-code"
      "aerospace"
      "antigravity"
      "olovebar"
    ];
    masApps = {
      "Amphetamine" = 937984704;
      "Xcode" = 497799835;
      "Keynote" = 409183694;
      "Pages" = 409201541;
      "v2RayTun" = 6476628951;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
