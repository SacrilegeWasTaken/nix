# Darwin-specific home-manager config (macOS paths, GUI tweaks, etc.).
# copyApps.enable = false avoids "App Management" permission (25.11+ uses copyApps by default and triggers the prompt).
{ config, pkgs, lib, ... }:

{
  imports = [ ./claude-code.nix ];

  config = lib.mkIf pkgs.stdenv.isDarwin {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          opacity = 0.88;
          padding = {
            x = 8;
            y = 8;
          };
          decorations = "Buttonless";
          option_as_alt = "Both";
        };

        font = {
          normal = {
            family = "JetBrainsMono Nerd Font Mono";
            style = "Regular";
          };
          bold = {
            family = "JetBrainsMono Nerd Font Mono";
            style = "Bold";
          };
          italic = {
            family = "JetBrainsMono Nerd Font Mono";
            style = "Italic";
          };
          size = 14.0;
        };

        scrolling.history = 50000;

        # Явно шлём xterm CSI для Ctrl+стрелок — Neovim в TUI понимает это как <C-Left> и т.д.
        keyboard.bindings = [
          { key = "Left"; mods = "Control"; chars = "\u001b[1;5D"; }
          { key = "Right"; mods = "Control"; chars = "\u001b[1;5C"; }
          { key = "Up"; mods = "Control"; chars = "\u001b[1;5A"; }
          { key = "Down"; mods = "Control"; chars = "\u001b[1;5B"; }
        ];
      };
    };

    # targets.darwin.copyApps.enable = true;
    # Extend as needed
  };
}
