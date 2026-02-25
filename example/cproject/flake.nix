{
  description = "Example: reproducible C++/Qt project with Nix (Darwin/Linux)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        isDarwin = pkgs.stdenv.isDarwin;
        isLinux = pkgs.stdenv.isLinux;

        # Common deps for a large C++ project
        commonPackages = with pkgs; [
          ccache cmake pkg-config
          qt5.qtbase qt5.qttools qt5.qtsvg qt5.qtserialport qt5.qtcharts
          ffmpeg-full boost eigen opencv glog gflags
          suitesparse ceres-solver hdf5 netcdf
        ] ++ (if isLinux then [ pkgs.g2o ] else []);

        # Platform-specific additions
        platform = if isDarwin then {
          packages = with pkgs; [ apple-sdk_26 ];
          shellHook = ''
            export SDKROOT="${pkgs.apple-sdk_26}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.0.sdk"
            export CMAKE_OSX_SYSROOT="$SDKROOT"
            export OSX_TARGET_ARCH="${if system == "x86_64-darwin" then "x86_64" else "arm64"}"
          '';
        } else {
          packages = [ ];
          shellHook = "";
        };

        allPackages = commonPackages ++ platform.packages;

        # Example reproducible build
        mkApp =
          if isDarwin then
            pkgs.stdenv.mkDerivation {
              pname = "example-app";
              version = "1.0.0";
              src = self;

              nativeBuildInputs = with pkgs; [ cmake ];
              buildInputs = allPackages;

              buildPhase = ''
                export HOME=$PWD
                mkdir build && cd build
                cmake .. \
                  -DCMAKE_BUILD_TYPE=Release \
                  -DCMAKE_PREFIX_PATH="${pkgs.qt5.qtbase};${pkgs.boost};${pkgs.opencv}"
                cmake --build . -j$NIX_BUILD_CORES
              '';

              installPhase = ''
                mkdir -p $out/bin
                cp build/example $out/bin/
              '';

              dontFixup = true;
            }
          else
            null;

        app = mkApp;

      in {
        packages = pkgs.lib.optionalAttrs isDarwin {
          default = app;
        };

        apps = pkgs.lib.optionalAttrs isDarwin {
          default = {
            type = "app";
            program = "${app}/bin/example";
          };
        };

        # Reproducible developer environment
        devShells.default = pkgs.mkShell {
          name = "example-dev-env";
          packages = allPackages;

          shellHook = ''
            export PROJECT_ROOT="$(pwd)"
            export CCACHE_DIR="$PROJECT_ROOT/.ccache"
            export CMAKE_C_COMPILER_LAUNCHER=ccache
            export CMAKE_CXX_COMPILER_LAUNCHER=ccache
            ${platform.shellHook}

            echo ""
            echo "Reproducible Nix dev environment ready"
            echo "Build: nix build"
            echo "Run: nix run"
            echo "Shell: nix develop"
            echo ""
          '';
        };
      }
    );
}