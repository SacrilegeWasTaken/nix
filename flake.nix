{
  description = "Unified NixOS + Darwin config for vietnamveteran";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };
    nikitabobko-tap = { url = "github:nikitabobko/homebrew-tap"; flake = false; };
    olovebar-tap = { url = "github:SacrilegeWasTaken/homebrew-tap"; flake = false; };
  };

  outputs = inputs @ { self, nix-darwin, nixpkgs, home-manager, nix-homebrew
    , homebrew-core, homebrew-cask, nikitabobko-tap, olovebar-tap, nixvim
    , ...
    }:
    let
      lib = nixpkgs.lib;
      pkgsFor = system: import nixpkgs { inherit system; config.allowUnfree = true; };
      # builtins.currentSystem requires --impure; throw with hint if unavailable.
      currentSystem = if builtins ? currentSystem then builtins.currentSystem else throw ''
        Builtins.currentSystem is not available (pure evaluation).
        Run with --impure:
          sudo darwin-rebuild switch --flake .#laptop --impure
          sudo nixos-rebuild switch --flake .#nixos --impure
      '';
      stateVersion = "25.11";
      dotfilesDir = self + "/dotfiles";
    in {
      formatter.${currentSystem} = (pkgsFor currentSystem).nixpkgs-fmt;

      # ---------- Darwin (macOS) ----------
      darwinConfigurations."laptop" = nix-darwin.lib.darwinSystem {
        system = currentSystem;
        specialArgs = {
          inherit inputs stateVersion dotfilesDir;
          self = inputs.self;
          nixvim = inputs.nixvim;
        };
        modules = [
          ./profiles/laptop.nix
          ./modules/darwin/00-base.nix
          ./modules/darwin/options.nix
          ./modules/darwin/system-packages.nix
          ./modules/darwin/homebrew.nix
          ./modules/darwin/fonts.nix
          ./modules/darwin/launchd.nix
          ./modules/darwin/fish.nix
          ./modules/nix/nix-settings.nix
          ./modules/common/dev/rust.nix
          ./modules/common/dev/haskell.nix
          ./modules/darwin/dev/julia.nix
          ./modules/apps/vscode.nix
          ./modules/apps/olovebar.nix
          ./modules/neovim/nixvim.nix
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "vietnamveteran";
              autoMigrate = true;
              mutableTaps = true;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "nikitabobko/homebrew-tap" = nikitabobko-tap;
                "SacrilegeWasTaken/homebrew-tap" = olovebar-tap;
              };
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit stateVersion dotfilesDir; };
            home-manager.users.vietnamveteran.imports = [
              ./home/default.nix
              ./modules/common/home/dotfiles.nix
            ];
          }
        ];
      };

      # ---------- NixOS (Linux) ----------
      nixosConfigurations.nixos = lib.nixosSystem {
        system = currentSystem;
        specialArgs = { inherit inputs stateVersion dotfilesDir; };
        modules = [
          ./profiles/laptop.nix
          ./hosts/nixos/configuration.nix
          ./modules/nix/nix-settings.nix
          ./modules/common/dev/rust.nix
          ./modules/common/dev/haskell.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit stateVersion dotfilesDir; };
            home-manager.users.vietnamveteran.imports = [
              ./home/default.nix
              ./modules/common/home/dotfiles.nix
            ];
          }
        ];
      };

      nixosConfigurations.nixos-vm = lib.nixosSystem {
        system = currentSystem;
        specialArgs = { inherit inputs stateVersion dotfilesDir; };
        modules = [
          ./profiles/vm.nix
          ./hosts/nixos-vm/configuration.nix
          ./modules/nix/nix-settings.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
}
