# Common Nix settings for Darwin and NixOS (caches, features).
# GC/optimise are set per-profile (laptop.nix / vm.nix).
{ config, lib, username, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      # Altami's own attic instance. Public for reads, no token; a write token
      # is only needed to publish. What it carries is the altami-studio
      # dependency set, which on Linux is Qt/ITK/VTK/OpenCV rebuilt against
      # glibc 2.35 and is on no public cache.
      "https://cache.altami.ru/attic/altami"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "altami:wAc+OzqFn+2xQ5B3deY8Jh6Eg7oMlUTMwUvcrdXSC3U="
    ];
    trusted-users = [ "root" "@admin" username ];
  };
}
