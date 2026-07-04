{ ... }:

{
  programs.zellij.enable = true;

  xdg.configFile."zellij/config.kdl".text = ''
    theme "gruvbox-dark"
    pane_frames false
    mouse_mode true
    copy_on_select true
    attach_to_session true
  '';

  xdg.configFile."zellij/layouts/dev.kdl".text = ''
    layout {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        pane split_direction="vertical" {
            pane size="25%" name="files" {
                command "yazi"
            }
            pane size="75%" name="editor" focus=true
        }
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
  '';
}
