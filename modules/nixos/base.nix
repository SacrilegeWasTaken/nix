# NixOS base: locale, timezone, networkmanager, xkb, base packages, fish, xdg.
{ config, pkgs, ... }:

{
  time.timeZone = "Asia/Krasnoyarsk";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  };

  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    fish
    firefox
    git-lfs
    code-cursor
    vscode
    kitty
    hyprland
    hyprpaper
    waybar
    foot
    swaybg
    zed-editor
  ];

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };
}
