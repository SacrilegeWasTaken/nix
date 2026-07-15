{ ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
    settings = {
      manager = {
        show_hidden = false;
        sort_by = "alphabetical";
        sort_dir_first = true;
        show_symlink = true;
      };
      opener = {
        edit = [{
          run = ''hx "$@"'';
          block = true;
          desc = "Helix";
        }];
      };
      open.rules = [
        { name = "*"; use = [ "edit" ]; }
      ];
    };
    keymap = {
      manager.prepend_keymap = [
        { on = [ "." ]; run = "toggle_hidden"; desc = "Toggle hidden files"; }
      ];
    };
  };
}
