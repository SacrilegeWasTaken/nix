# Dotfiles from repo dotfiles/: common (both), darwin (macOS only), nixos (Linux only).
# Path dotfilesDir is passed from the flake (self + "/dotfiles").
{ config, pkgs, lib, dotfilesDir ? null, ... }:

lib.mkIf (dotfilesDir != null) {
  # ---------- Common (Darwin + NixOS) ----------
  xdg.configFile = lib.mkMerge [
    {
      "starship.toml".source = dotfilesDir + "/common/starship.toml";
      "kitty/kitty.conf".source = dotfilesDir + "/common/kitty.conf";
      "zed" = { source = dotfilesDir + "/common/zed"; force = true; };
      "neofetch/config.conf".source = dotfilesDir + "/common/config.conf";
    }
    # ---------- Darwin only ----------
    (lib.mkIf pkgs.stdenv.isDarwin {
      "olovebar/olovebar.toml".source = dotfilesDir + "/darwin/olovebar.toml";
      "aerospace/aerospace.toml".source = dotfilesDir + "/darwin/aerospace.toml";
      "tmux/tmux.conf".source = dotfilesDir + "/darwin/tmux.conf";
    })
    # ---------- NixOS (Linux) only ----------
    (lib.mkIf (! pkgs.stdenv.isDarwin) {
      "tmux/tmux.conf".source = dotfilesDir + "/nixos/tmux.conf";
    })
  ];

  # tmux: Darwin and NixOS have different files
  home.file.".tmux.conf".source = dotfilesDir + (
    if pkgs.stdenv.isDarwin then "/darwin/tmux.conf" else "/nixos/tmux.conf"
  );
}
