# Facebook Infer, taken from the upstream prebuilt macOS release.
#
# nixpkgs does package infer, but only as a source build: ~180 OCaml derivations
# with nothing in the binary cache for aarch64-darwin, redone on every bump of
# that stack. The upstream tarball is prebuilt; the price is two absolute
# Homebrew paths baked into its load commands:
#
#   /opt/homebrew/opt/zstd/lib/libzstd.1.dylib  (23 binaries, bundled clang included)
#   /opt/homebrew/opt/gmp/lib/libgmp.10.dylib   (the infer binary alone)
#
# Both are rewritten to @loader_path next to a symlink into the nix store.
# @loader_path rather than a plain store path because install_name_tool can only
# rewrite a load command in place: a store path is longer than the Homebrew one
# and the infer binary has padding for at most one such rewrite, whereas
# "@loader_path/libzstd.1.dylib" is shorter than the original and always fits.
{ lib, stdenvNoCC, fetchurl, gmp, zstd, darwin }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "infer";
  version = "1.3.0";

  src = fetchurl {
    url = "https://github.com/facebook/infer/releases/download/v${finalAttrs.version}/infer-osx-arm64-v${finalAttrs.version}.tar.xz";
    hash = "sha256-YOzNIx4n8qPWWUfvdbmtzRmDUoKWvR2m9nptoC4iqW4=";
  };

  nativeBuildInputs = [ darwin.cctools darwin.autoSignDarwinBinariesHook ];

  # The release ships stripped and signed; stripping again would only invalidate
  # signatures that the signing hook then has to redo.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a bin lib share $out/

    # -r skips symlinks, so bin/* (all symlinks into lib) is not visited twice.
    referencing=$(grep -rl /opt/homebrew $out)

    for dir in $(echo "$referencing" | xargs -n1 dirname | sort -u); do
      ln -s ${lib.getLib zstd}/lib/libzstd.1.dylib $dir/libzstd.1.dylib
      ln -s ${lib.getLib gmp}/lib/libgmp.10.dylib $dir/libgmp.10.dylib
    done

    for binary in $referencing; do
      install_name_tool \
        -change /opt/homebrew/opt/zstd/lib/libzstd.1.dylib @loader_path/libzstd.1.dylib \
        -change /opt/homebrew/opt/gmp/lib/libgmp.10.dylib @loader_path/libgmp.10.dylib \
        $binary
    done

    runHook postInstall
  '';

  # Exercises the rewritten load commands and the ad-hoc signatures: a leftover
  # Homebrew reference or a broken signature makes this fail to launch.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/infer --version
    runHook postInstallCheck
  '';

  meta = {
    description = "Static analyzer for Java, C++, Objective-C, and C";
    homepage = "https://fbinfer.com/";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "infer";
  };
})
