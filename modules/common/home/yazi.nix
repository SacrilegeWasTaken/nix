{ ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
    settings = {
      mgr = {
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
        { url = "*"; use = [ "edit" ]; }
      ];
    };
    keymap = {
      mgr.prepend_keymap = [
        { on = [ "." ]; run = "hidden toggle"; desc = "Toggle hidden files"; }
      ];
    };
  };
}
