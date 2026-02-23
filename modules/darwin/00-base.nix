# Darwin base: system identity, platform, allowUnfree. GC is in profiles/laptop.nix.
{ config, pkgs, self, ... }:

{
  nixpkgs.config.allowUnfree = true;
  programs.fish.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = "vietnamveteran";
  system.stateVersion = 6;
  nixpkgs.hostPlatform = config.system.build.platform;

  # nix-darwin specific GC interval (profile sets gc.automatic/options)
  nix.gc.interval = { Hour = 12; };
}
