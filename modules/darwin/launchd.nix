{ config, pkgs, ... }:

{
  launchd.user.agents = {
    "com.vietnamveteran.raycast" = {
      command = "/usr/bin/open -a Raycast";
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = false;
      serviceConfig.StandardOutPath = "/tmp/com.vietnamveteran.raycast.out.log";
      serviceConfig.StandardErrorPath = "/tmp/com.vietnamveteran.raycast.err.log";
    };
    "com.vietnamveteran.aerospace" = {
      command = "/usr/bin/open -a Aerospace";
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = false;
      serviceConfig.StandardOutPath = "/tmp/com.vietnamveteran.aerospace.out.log";
      serviceConfig.StandardErrorPath = "/tmp/com.vietnamveteran.aerospace.err.log";
    };
    "com.vietnamveteran.olovebar" = {
      command = "/usr/bin/open -a OLoveBar";
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = false;
      serviceConfig.StandardOutPath = "/tmp/com.vietnamveteran.olovebar.out.log";
      serviceConfig.StandardErrorPath = "/tmp/com.vietnamveteran.olovebar.err.log";
    };
  };
}
