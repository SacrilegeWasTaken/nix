# Dotfiles from repo dotfiles/: common (both), darwin (macOS only), nixos (Linux only).
# Path dotfilesDir is passed from the flake (self + "/dotfiles").
{ config, pkgs, lib, dotfilesDir ? null, ... }:

lib.mkIf (dotfilesDir != null) {
  # ---------- Common (Darwin + NixOS) ----------
  xdg.configFile = lib.mkMerge [
    {
      "starship.toml".source = dotfilesDir + "/common/starship.toml";
      "zed" = { source = dotfilesDir + "/common/zed"; force = true; };
      "neofetch/config.conf".source = dotfilesDir + "/common/config.conf";
    }
    # ---------- Darwin only ----------
    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      "aerospace/aerospace.toml".source = dotfilesDir + "/darwin/aerospace.toml";
      "olovebar/olovebar.toml".source = dotfilesDir + "/darwin/olovebar.toml";
      "tmux/tmux.conf".source = dotfilesDir + "/darwin/tmux.conf";
    })
    # ---------- NixOS (Linux) only ----------
    (lib.mkIf (! pkgs.stdenv.hostPlatform.isDarwin) {
      "tmux/tmux.conf".source = dotfilesDir + "/nixos/tmux.conf";
    })
  ];

  # tmux: Darwin and NixOS have different files
  home.file.".tmux.conf".source = dotfilesDir + (
    if pkgs.stdenv.hostPlatform.isDarwin then "/darwin/tmux.conf" else "/nixos/tmux.conf"
  );

  # Claude Code: глобальный контекст (см. dotfiles/common/claude/CLAUDE.md)
  home.file.".claude/CLAUDE.md".source = dotfilesDir + "/common/claude/CLAUDE.md";
}
