# Darwin-specific home-manager config (macOS paths, GUI tweaks, etc.).
# copyApps.enable = false avoids "App Management" permission (25.11+ uses copyApps by default and triggers the prompt).
{ config, pkgs, lib, ... }:

{
  imports = [ ./claude-code.nix ./codex.nix ];

  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    # ApplePressAndHoldEnabled (set in darwin/00-base.nix via system.defaults)
    # keeps getting reset by macOS, so it is reapplied on every rebuild and
    # at every login.
    home.activation.disablePressAndHold = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      /usr/bin/defaults write -g ApplePressAndHoldEnabled -bool false
    '';

    launchd.agents.disable-press-and-hold = {
      enable = true;
      config = {
        ProgramArguments = [
          "/usr/bin/defaults"
          "write"
          "-g"
          "ApplePressAndHoldEnabled"
          "-bool"
          "false"
        ];
        RunAtLoad = true;
      };
    };

    # targets.darwin.copyApps.enable = true;
    # Extend as needed
  };
}
