{ ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      hide_window_decorations = "titlebar-only";
      background_opacity = "0.7";
      # Option acts as Alt so Alt+<key> zellij binds work (no macOS
      # accent-compose); ignored on Linux.
      macos_option_as_alt = "both";
    };
  };
}
