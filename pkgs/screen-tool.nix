{ stdenv, swift }:

stdenv.mkDerivation {
  pname = "screen-tool";
  version = "1.0.0";
  src = ./screen-tool.swift;
  dontUnpack = true;
  nativeBuildInputs = [ swift ];

  buildPhase = ''
    runHook preBuild
    swiftc "$src" -framework ApplicationServices -o screen-tool
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 screen-tool "$out/bin/screen-tool"
    runHook postInstall
  '';

  meta.description = "Capture the screen and click precise coordinates on macOS";
}
