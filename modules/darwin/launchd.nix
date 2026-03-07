{ config, pkgs, username, ... }:

{
  launchd.user.agents = {
    "com.${username}.raycast" = {
      command = "/usr/bin/open -a Raycast";
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = false;
      serviceConfig.StandardOutPath = "/tmp/com.${username}.raycast.out.log";
      serviceConfig.StandardErrorPath = "/tmp/com.${username}.raycast.err.log";
    };
    "com.${username}.aerospace" = {
      command = "/usr/bin/open -a Aerospace";
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = false;
      serviceConfig.StandardOutPath = "/tmp/com.${username}.aerospace.out.log";
      serviceConfig.StandardErrorPath = "/tmp/com.${username}.aerospace.err.log";
    };
    "com.${username}.olovebar" = {
      command = "/usr/bin/open -a OLoveBar";
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = false;
      serviceConfig.StandardOutPath = "/tmp/com.${username}.olovebar.out.log";
      serviceConfig.StandardErrorPath = "/tmp/com.${username}.olovebar.err.log";
    };
  };
}
