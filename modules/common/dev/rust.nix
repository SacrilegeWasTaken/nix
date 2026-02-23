# Rust: rustup from nixpkgs + configurable toolchains/components/targets/cargo-tools.
# On each rebuild, activation script runs: rustup update + install from config.rust.*.
{ config, pkgs, lib, ... }:

let
  rustupBin = "${pkgs.rustup}/bin/rustup";
  # Home dir: Darwin uses system.primaryUser, NixOS uses users.users.<rust.user>.home
  rustUser = config.rust.user;
  rustHome = if config.system ? primaryUser
    then "/Users/${config.system.primaryUser}"
    else (config.users.users.${config.rust.user}.home or "/home/${config.rust.user}");
  installScript = ''
    echo "=== Rust toolchain (rustup) ==="
    if [ -x "${rustupBin}" ]; then
      export RUSTUP_PATH="${rustupBin}"
      sudo -u ${rustUser} -H env HOME="${rustHome}" "$RUSTUP_PATH" update
      ${lib.concatMapStringsSep "\n" (t: ''
        sudo -u ${rustUser} -H env HOME="${rustHome}" "$RUSTUP_PATH" toolchain install ${t}
      '') config.rust.toolchains}
      sudo -u ${rustUser} -H env HOME="${rustHome}" "$RUSTUP_PATH" default stable
      ${lib.concatMapStringsSep "\n" (c: ''
        sudo -u ${rustUser} -H env HOME="${rustHome}" "$RUSTUP_PATH" component add ${c}
      '') config.rust.components}
      ${lib.concatMapStringsSep "\n" (t: ''
        sudo -u ${rustUser} -H env HOME="${rustHome}" "$RUSTUP_PATH" target add ${t}
      '') config.rust.targets}
      ${if config.rust.miri then ''
        sudo -u ${rustUser} -H env HOME="${rustHome}" "$RUSTUP_PATH" +nightly component add miri
      '' else ""}
      ${lib.concatMapStringsSep "\n" (tool: ''
        sudo -u ${rustUser} -H env HOME="${rustHome}" "$RUSTUP_PATH" run stable cargo install ${tool}
      '') config.rust.cargoStableTools}
      echo "Rust toolchain done."
    else
      echo "rustup not found, skip." >&2
    fi
  '';
in
{
  options.rust = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "vietnamveteran";
      description = "User to run rustup (home dir derived from system/darwin or users.users)";
    };
    toolchains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "stable" "nightly" ];
      description = "Rust toolchains to install (e.g. stable, nightly)";
    };
    components = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "rust-src" "rustfmt" "clippy" ];
      description = "Rust components to install";
    };
    targets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "x86_64-unknown-linux-gnu" "wasm32-unknown-unknown" ];
      description = "Rust targets to add";
    };
    cargoStableTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "cargo-make" "wasm-pack" "cross" ];
      description = "Cargo tools to install (cargo install)";
    };
    miri = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Miri on nightly";
    };
  };

  config = {
    environment.systemPackages = [ pkgs.rustup ];
    environment.extraInit = ''
      [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
      export CARGO_HOME="$HOME/.cargo"
    '';

    # Run on every rebuild. nix-darwin only runs hardcoded scripts (postActivation etc.), so append here; NixOS runs named activationScripts.
    system.activationScripts.rustup = lib.mkIf (!(config.system ? primaryUser)) {
      text = installScript;
      deps = lib.optional (config.system.activationScripts ? users) "users";
    };
    system.activationScripts.postActivation.text = lib.mkIf (config.system ? primaryUser) (lib.mkAfter installScript);
  };
}
