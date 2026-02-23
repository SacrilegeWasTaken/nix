# Darwin fish: shell init, default shell. Common fish config can live in home-manager (modules/common/home/fish.nix).
{ config, pkgs, ... }:

{
  programs.fish = {
    shellInit = ''
      set -g fish_greeting ""
      set -g fish_color_command brgreen --bold
      set -g fish_color_error brred --bold
      if command -v docker >/dev/null 2>&1
        set -gx CROSS_CONTAINER_ENGINE "docker"
      end
      if test -S "$HOME/.docker/run/docker.sock"
        set -gx DOCKER_HOST "unix://$HOME/.docker/run/docker.sock"
      else if test -S "/var/run/docker.sock"
        set -gx DOCKER_HOST "unix:///var/run/docker.sock"
      end
      set -gx CARGO_HOME "$HOME/.cargo"
    '';
    interactiveShellInit = ''
      starship init fish | source
      alias vim="nvim"
      if command -v docker >/dev/null 2>&1
        set -gx CROSS_CONTAINER_ENGINE "docker"
      end
      if test -S "$HOME/.docker/run/docker.sock"
        set -gx DOCKER_HOST "unix://$HOME/.docker/run/docker.sock"
      else if test -S "/var/run/docker.sock"
        set -gx DOCKER_HOST "unix:///var/run/docker.sock"
      end
      set -gx CARGO_HOME "$HOME/.cargo"
    '';
  };

  environment.shells = [ pkgs.fish ];
  users.users.${config.system.primaryUser} = {
    shell = pkgs.fish;
  };
}
