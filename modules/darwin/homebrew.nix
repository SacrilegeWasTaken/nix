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
