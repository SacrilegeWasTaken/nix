{ config, pkgs, ... }:

{
  users.users.vietnamveteran = {
    isNormalUser = true;
    description = "vietnamveteran";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
  };
}
