# OpenAI Codex CLI, pinned to a newer release than nixpkgs.
#
# Codex ships "every other day" and nixpkgs lags; this copies nixpkgs'
# pkgs/by-name/co/codex/package.nix and bumps only the moving parts: version +
# src hash, the cargo vendor hash, and the two prebuilt V8 artifacts (the
# `v8` crate version from Cargo.lock drives the rusty_v8 release tag): the
# static archive plus the generated `src_binding_*.rs` it must match. Both are
# inlined (nixpkgs' ./librusty_v8*.nix are auto-generated and not a stable
# interface).
#
# Bump procedure: set `version`, fill `src.hash` from a fetchFromGitHub with a
# fake hash, set `v8Version`/`v8Shas`/`v8SrcBindingShas` from the matching
# rusty_v8 release, then build once with a fake `cargoHash` and paste the
# "got:" hash from the error.
{ lib, stdenv, rustPlatform, fetchFromGitHub, fetchurl, installShellFiles
, bubblewrap, clang, cmake, gitMinimal, libcap, libclang, lld, makeBinaryWrapper
, pkg-config, openssl, ripgrep, versionCheckHook
, installShellCompletions ? stdenv.buildPlatform.canExecute stdenv.hostPlatform }:

let
  v8Version = "150.4.0";
  v8Shas = {
    x86_64-linux = "sha256-WGn9twcbHyHyAKl86X0gElh34PMc2ALtmd4sU/SIsGw=";
    aarch64-linux = "sha256-txd9Uq0zNycv4NO453gjnIIalcJdWVnexiue/WVPfdM=";
    aarch64-darwin = "sha256-zNj4FIW4IsWxiuun+d65KaM4LYasZzu/DzZvBod+axA=";
  };
  v8SrcBindingShas = {
    x86_64-linux = "sha256-dyeCauR5vbZF6Acjn7EtH44uI956bPFvXuWSaQ0dhQY=";
    aarch64-linux = "sha256-dyeCauR5vbZF6Acjn7EtH44uI956bPFvXuWSaQ0dhQY=";
    aarch64-darwin = "sha256-ylrfDPicmnCtRgrnNkiy/om3SqETs8t/dXtqArdYOU8=";
  };
  librusty_v8 = fetchurl {
    name = "librusty_v8-${v8Version}";
    url = "https://github.com/denoland/rusty_v8/releases/download/v${v8Version}/librusty_v8_release_${stdenv.hostPlatform.rust.rustcTarget}.a.gz";
    sha256 = v8Shas.${stdenv.hostPlatform.system};
    meta = {
      version = v8Version;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  };
  librusty_v8_src_binding = fetchurl {
    name = "librusty_v8_src_binding-${v8Version}";
    url = "https://github.com/denoland/rusty_v8/releases/download/v${v8Version}/src_binding_release_${stdenv.hostPlatform.rust.rustcTarget}.rs";
    sha256 = v8SrcBindingShas.${stdenv.hostPlatform.system};
    meta = {
      version = v8Version;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "codex";
  version = "0.153.4";

  src = fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${finalAttrs.version}";
    hash = "sha256-lHiDj5SodaM3mh8goMm6esfejeAT+Y3JJWrRnyj6sJo=";
  };

  sourceRoot = "${finalAttrs.src.name}/codex-rs";

  cargoHash = "sha256-GG6kOXmCdq+bZLU2ul0DIVL8lDuweayvZvXn6+bcUZw=";

  __structuredAttrs = true;

  # Match upstream's release build for the codex binary, plus its
  # codex-code-mode-host runtime companion for out-of-process V8 execution.
  cargoBuildFlags = [
    "--package"
    "codex-cli"
    "--package"
    "codex-code-mode-host"
  ];
  cargoCheckFlags = [
    "--package"
    "codex-cli"
    "--package"
    "codex-code-mode-host"
  ];

  postPatch = ''
    substituteInPlace Cargo.toml \
      --replace-fail 'lto = "thin"' "" \
      --replace-fail 'codegen-units = 4' ""
  '';

  nativeBuildInputs = [
    clang
    cmake
    gitMinimal
    installShellFiles
    makeBinaryWrapper
    pkg-config
  ];

  buildInputs = [
    libclang
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libcap
  ];

  # NOTE: set LIBCLANG_PATH so bindgen can locate libclang, and adjust
  # warning-as-error flags to avoid known false positives (GCC's
  # stringop-overflow in BoringSSL's a_bitstr.cc) while keeping Clang's
  # character-conversion warning-as-error disabled.
  env = {
    LIBCLANG_PATH = "${lib.getLib libclang}/lib";
    NIX_CFLAGS_COMPILE = toString (
      lib.optionals stdenv.cc.isGNU [
        "-Wno-error=stringop-overflow"
      ]
      ++ lib.optionals stdenv.cc.isClang [
        "-Wno-error=character-conversion"
      ]
    );
    RUSTY_V8_ARCHIVE = librusty_v8;
    RUSTY_V8_SRC_BINDING_PATH = librusty_v8_src_binding;
  }
  // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    # Link with lld on Darwin. nixpkgs' classic open-source ld64 fails to insert
    # ARM64 branch thunks for this binary, producing `b(l) ARM64 branch out of range`.
    NIX_CFLAGS_LINK = "-fuse-ld=${lib.getExe' lld "ld64.lld"}";
  };

  # Upstream's test suite needs networking, shells and system config; nixpkgs
  # disables it for the same reason (fast-moving target).
  doCheck = false;

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd codex \
      --bash <($out/bin/codex completion bash) \
      --fish <($out/bin/codex completion fish) \
      --zsh <($out/bin/codex completion zsh)
  '';

  postFixup = ''
    wrapProgram $out/bin/codex --prefix PATH : ${
      lib.makeBinPath ([ ripgrep ] ++ lib.optionals stdenv.hostPlatform.isLinux [ bubblewrap ])
    }
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://raw.githubusercontent.com/openai/codex/refs/tags/rust-v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = lib.platforms.unix;
  };
})
