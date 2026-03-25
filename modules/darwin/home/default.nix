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
        # Ctrl+стрелки: Alacritty шлёт xterm CSI по умолчанию (\e[1;5D и т.д.).
        # Маппинг <C-Left> → wincmd — в Neovim через langmapper.original_set.
      };
    };

    # targets.darwin.copyApps.enable = true;
    # Extend as needed
  };
}
