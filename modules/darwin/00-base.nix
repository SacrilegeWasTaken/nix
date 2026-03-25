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
        # Mission Control (Ctrl+↑)
        "32" = { enabled = false; };
        "33" = { enabled = false; };
        # Application Windows (Ctrl+↓)
        "34" = { enabled = false; };
        "35" = { enabled = false; };
        # Show Desktop (F11)
        "36" = { enabled = false; };
        "37" = { enabled = false; };
        # Move left/right a space (Ctrl+←/→)
        "79" = { enabled = false; };
        "80" = { enabled = false; };
        "81" = { enabled = false; };
        "82" = { enabled = false; };
        # Switch to Desktop 1–9 (Ctrl+1…9)
        "118" = { enabled = false; };
        "119" = { enabled = false; };
        "120" = { enabled = false; };
        "121" = { enabled = false; };
        "122" = { enabled = false; };
        "123" = { enabled = false; };
        "124" = { enabled = false; };
        "125" = { enabled = false; };
        "126" = { enabled = false; };
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
