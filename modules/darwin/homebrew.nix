# Homebrew taps, casks, mas. brews: juliaup added in modules/darwin/julia.nix; ghcup not needed (Haskell from nix).
{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
      "nikitabobko/homebrew-tap"
      "SacrilegeWasTaken/homebrew-tap"
    ];
    brews = [
      "mas"
      "swiftformat"
      "xcodes"
    ];
    casks = [
      "discord"
      "cursor"
      "olovebar"
      "zen"
      "raycast"
      "docker-desktop"
      "visual-studio-code"
      "warp"
      "nikitabobko/tap/aerospace"
    ];
    masApps = {
      "Amphetamine" = 937984704;
      "Xcode" = 497799835;
      "Keynote" = 409183694;
      "Pages" = 409201541;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
