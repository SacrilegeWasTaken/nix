{
  # description: keep in sync with username in outputs
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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };
    nikitabobko-tap = { url = "github:nikitabobko/homebrew-tap"; flake = false; };
    sacrilegewastaken-tap = { url = "git+https://codeberg.org/sacrilegewastaken/tap.git"; flake = false; };
    olovebar = { url = "git+https://codeberg.org/sacrilegewastaken/olovebar.git"; flake = false; };
  };

  outputs = inputs @ { self, nix-darwin, nixpkgs, home-manager, nix-homebrew
    , homebrew-core, homebrew-cask, nikitabobko-tap, sacrilegewastaken-tap, nixvim
    , sops-nix, ...
    }:
    let
      lib = nixpkgs.lib;
      username = "vietnamveteran";
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
          inherit inputs stateVersion dotfilesDir username;
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
          sops-nix.darwinModules.sops
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = username;
              autoMigrate = true;
              mutableTaps = false;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "nikitabobko/homebrew-tap" = nikitabobko-tap;
                "sacrilegewastaken/homebrew-tap" = sacrilegewastaken-tap;
              };
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit stateVersion dotfilesDir username; };
            home-manager.users.${username}.imports = [
              ./home/default.nix
              ./modules/common/home/dotfiles.nix
            ];
          }
        ];
      };

      # ---------- NixOS (Linux) ----------
      nixosConfigurations.nixos = lib.nixosSystem {
        system = currentSystem;
        specialArgs = { inherit inputs stateVersion dotfilesDir username; };
        modules = [
          ./profiles/laptop.nix
          ./hosts/nixos/configuration.nix
          ./modules/nix/nix-settings.nix
          ./modules/common/dev/rust.nix
          ./modules/common/dev/haskell.nix
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit stateVersion dotfilesDir username; };
            home-manager.users.${username}.imports = [
              ./home/default.nix
              ./modules/common/home/dotfiles.nix
            ];
          }
        ];
      };

      nixosConfigurations.nixos-vm = lib.nixosSystem {
        system = currentSystem;
        specialArgs = { inherit inputs stateVersion dotfilesDir username; };
        modules = [
          ./profiles/vm.nix
          ./hosts/nixos-vm/configuration.nix
          ./modules/nix/nix-settings.nix
          ./modules/nixos/desktop/gnome.nix
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
}
