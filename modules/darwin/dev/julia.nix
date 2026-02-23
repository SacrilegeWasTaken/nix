# Julia on Darwin only: juliaup via Homebrew + configurable channels/packages.
{ config, pkgs, lib, ... }:

let
  juliaUser = config.julia.user;
  juliaHome =
    if config.system ? primaryUser then "/Users/${config.system.primaryUser}"
    else "/Users/${juliaUser}";

  installScript = ''
    echo "=== Julia toolchain (juliaup) ==="

    # Find juliaup
    if [ -x "/opt/homebrew/bin/juliaup" ]; then
      JULIAUP_PATH="/opt/homebrew/bin/juliaup"
    elif [ -x "/usr/local/bin/juliaup" ]; then
      JULIAUP_PATH="/usr/local/bin/juliaup"
    elif command -v juliaup >/dev/null 2>&1; then
      JULIAUP_PATH="$(command -v juliaup)"
    else
      JULIAUP_PATH=""
    fi

    if [ -n "$JULIAUP_PATH" ]; then
      echo "Using juliaup at $JULIAUP_PATH for user ${juliaUser} (HOME=${juliaHome})"
      sudo -u ${juliaUser} -H env HOME="${juliaHome}" "$JULIAUP_PATH" self update || echo "juliaup self update not available"

      ${lib.concatMapStringsSep "\n" (ch: ''
        sudo -u ${juliaUser} -H env HOME="${juliaHome}" "$JULIAUP_PATH" add ${ch}
      '') config.julia.channels}

      sudo -u ${juliaUser} -H env HOME="${juliaHome}" "$JULIAUP_PATH" default ${config.julia.defaultChannel}
      sudo -u ${juliaUser} -H env HOME="${juliaHome}" "$JULIAUP_PATH" update

      ${if config.julia.packages != [ ] then ''
        echo "Installing Julia packages..."
        sudo -u ${juliaUser} -H env HOME="${juliaHome}" sh -c '
          if [ -x "/opt/homebrew/bin/julia" ]; then
            JULIA=\"/opt/homebrew/bin/julia\"
          elif [ -x \"$HOME/.juliaup/bin/julia\" ]; then
            JULIA=\"$HOME/.juliaup/bin/julia\"
          elif command -v julia >/dev/null 2>&1; then
            JULIA=\"$(command -v julia)\"
          else
            echo \"Julia binary not found, skipping package installation\"
            exit 0
          fi

          '${lib.concatMapStringsSep "\n" (pkg: ''
            "$JULIA" -e "using Pkg; Pkg.add(\"${pkg}\")"
          '') config.julia.packages}'
        '
      '' else ""}

      echo "Julia setup done."
    else
      echo "juliaup not found; ensure it is in homebrew.brews" >&2
    fi
  '';
in
{
  options.julia = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "vietnamveteran";
      description = "User to run juliaup (Darwin only).";
    };

    channels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "release" ];
      description = "Julia channels to install (release, lts, rc, etc.).";
    };

    defaultChannel = lib.mkOption {
      type = lib.types.str;
      default = "release";
      description = "Default Julia channel (as seen by juliaup).";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Julia packages to install globally via Pkg.add.";
      example = [ "Plots" "DataFrames" "IJulia" ];
    };
  };

  config = {
    # Ensure juliaup is present
    homebrew.brews = [ "juliaup" ];

    environment.extraInit = ''
      [ -d "$HOME/.juliaup/bin" ] && export PATH="$HOME/.juliaup/bin:$PATH"
    '';

    # nix-darwin only runs postActivation (no custom script names), so append here.
    system.activationScripts.postActivation.text = lib.mkAfter installScript;
  };
}
