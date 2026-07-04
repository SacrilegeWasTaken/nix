# Common home-manager fish config (Darwin and NixOS).
{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;
    functions = {
      # Launch zellij with yazi sidebar + editor layout.
      # Equivalent to yazelix without the build-time hell.
      yzx = {
        description = "Start yazi + zellij dev session";
        body = ''
          if set -q ZELLIJ_SESSION_NAME
            echo "Already inside a zellij session"
          else
            zellij --layout dev
          end
        '';
      };

      __zellij_tab_name = {
        onEvent = "fish_preexec";
        body = ''
          if set -q ZELLIJ_SESSION_NAME
              set -l cmd (string split ' ' -- $argv)[1]
              zellij action rename-tab (basename -- $cmd) >/dev/null 2>&1
          end
        '';
      };

      __zellij_tab_reset = {
        onEvent = "fish_prompt";
        body = ''
          if set -q ZELLIJ_SESSION_NAME
              zellij action rename-tab (basename -- $PWD) >/dev/null 2>&1
          end
        '';
      };
    };
  };
}
