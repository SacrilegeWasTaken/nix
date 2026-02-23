# NixOS VM (Parallels on Mac, aarch64). Declarative: use partition label.
# When creating the VM disk, give the root partition label "nixos" (e.g. e2label /dev/sdX1 nixos after install).
{ config, lib, pkgs, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault config.system.build.platform;
  hardware.parallels.enable = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "prl-tools" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
