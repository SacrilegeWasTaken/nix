# Hardware for NixOS laptop (real machine). Declarative: use partition labels.
# At install time set root label to "nixos" and boot to "NIXOS_BOOT" (e.g. e2label /dev/sdX1 nixos; fatlabel /dev/sdX2 NIXOS_BOOT).
{ config, lib, pkgs, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault config.system.build.platform;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXOS_BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
}
