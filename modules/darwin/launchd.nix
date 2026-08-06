{ config, pkgs, username, ... }:

let
  bazelRemoteDir = "/Users/${username}/.cache/bazel-remote";
in
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
    # Local REAPI cache for buck2/bazel builds (Homebrew formula, see homebrew.nix).
    # bazel-remote refuses to start without an existing --dir, and it has no flag
    # to turn the HTTP listener off, so both are handled here: the cache dir is
    # created on start and HTTP is pinned to loopback next to the gRPC port.
    "com.${username}.bazel-remote" = {
      script = ''
        /bin/mkdir -p ${bazelRemoteDir}
        exec /opt/homebrew/bin/bazel-remote \
          --dir ${bazelRemoteDir} \
          --max_size 50 \
          --http_address localhost:9091 \
          --grpc_address localhost:9092
      '';
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = true;
      serviceConfig.StandardOutPath = "/tmp/com.${username}.bazel-remote.out.log";
      serviceConfig.StandardErrorPath = "/tmp/com.${username}.bazel-remote.err.log";
    };
  };
}
