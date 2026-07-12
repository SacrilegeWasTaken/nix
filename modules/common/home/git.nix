# Common home-manager git config.
{ config, pkgs, lib, osConfig, ... }:

{
  programs.git = {
    enable = true;
    userName = "Leonid";
    userEmail = "superdjskater@mail.ru";

    # OpenPGP commit signing. The secret key is provisioned via sops
    # (secrets/default.yaml -> imported below); only its id is declared here.
    signing = {
      key = "5C661C0DED24D08C";
      signByDefault = true;
    };

    # Pin the gpg binary so signing works regardless of PATH ordering.
    extraConfig.gpg.program = "${pkgs.gnupg}/bin/gpg";
  };

  # Provide the gpg toolchain (gpg, gpg-agent) used for signing.
  programs.gpg.enable = true;

  # Import the sops-provisioned signing key into the user keyring. Idempotent:
  # re-importing an already-present key is a no-op. Runs after sops has
  # decrypted the secret at system-activation time.
  home.activation.importGpgSigningKey =
    let
      keyPath = osConfig.sops.secrets.gpg-signing-key.path or null;
    in
    lib.mkIf (keyPath != null) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -f "${keyPath}" ]; then
          ${pkgs.gnupg}/bin/gpg --batch --import "${keyPath}" 2>/dev/null || true
        fi
      ''
    );
}
