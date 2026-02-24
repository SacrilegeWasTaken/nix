# NixOS VM host (Parallels, arm64). Uses profile vm (lightweight).
# Imports modules/nixos/* when they exist (see nixos-hosts todo).
# Hardware (incl. hardware.parallels.enable for display auto-resize) from /etc/nixos/hardware-configuration.nix.
{ config, pkgs, stateVersion, ... }:

{
  imports = [
    "/etc/nixos/hardware-configuration.nix"
  ];

  networking.hostName = "nixos-vm";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  nixpkgs.config.allowUnfree = true;

  # Русская локаль и раскладка
  i18n.defaultLocale = "ru_RU.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "ru_RU.UTF-8/UTF-8" ];

  console.keyMap = "ru";

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us,ru";
      variant = "";
      options = "grp:alt_shift_toggle";
    };
  };

  # Разрешение подстраивается под окно VM через Parallels Tools (prl-tools из /etc/nixos/hardware-configuration.nix).

  programs.fish.enable = true;
  users.users.vietnamveteran = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  users.defaultUserShell = pkgs.fish;

  system.stateVersion = stateVersion;
}
