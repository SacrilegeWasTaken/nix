# Darwin base: system identity, allowUnfree. GC is in profiles/laptop.nix.
# hostPlatform is implied by darwinSystem's system (e.g. aarch64-darwin).
{ config, pkgs, lib, self, username, ... }:

{
  nixpkgs.config.allowUnfree = true;
  programs.fish.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = username;
  system.stateVersion = 6;

  # nix-darwin specific GC interval (profile sets gc.automatic/options)
  nix.gc.interval = { Hour = 12; };

  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # Mission Control (часто Ctrl+↑), окна приложений (часто Ctrl+↓), «Показать рабочий стол»
        "32" = { enabled = false; };
        "34" = { enabled = false; };
        "36" = { enabled = false; };
        # Переход между столами (часто Ctrl+← / Ctrl+→)
        "79" = { enabled = false; };
        "80" = { enabled = false; };
        "81" = { enabled = false; };
        "82" = { enabled = false; };
      };
    };
  };

  # Иначе plist иногда не подхватывается до выхода из сеанса
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo >&2 "nix-darwin: reloading keyboard shortcut preferences..."
    sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null \
      || true
  '';
}
