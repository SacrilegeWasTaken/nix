# Darwin-specific home-manager config (macOS paths, GUI tweaks, etc.).
# copyApps.enable = false avoids "App Management" permission (25.11+ uses copyApps by default and triggers the prompt).
{ config, pkgs, lib, ... }:

{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    targets.darwin.copyApps.enable = false;
    # Extend as needed
  };
}
