# Darwin base: system identity, allowUnfree. GC is in profiles/laptop.nix.
# hostPlatform is implied by darwinSystem's system (e.g. aarch64-darwin).
{ config, pkgs, self, username, ... }:

{
  nixpkgs.config.allowUnfree = true;
  programs.fish.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = username;
  system.stateVersion = 6;

  # nix-darwin specific GC interval (profile sets gc.automatic/options)
  nix.gc.interval = { Hour = 12; };
}
