# Darwin / NixOS flake

Unified configuration for:
- macOS (nix-darwin) laptop
- NixOS laptop
- NixOS VM (GNOME, Parallels)

Everything is driven by a single `flake.nix`.

## Layout

- `flake.nix` – entrypoint, defines:
  - `darwinConfigurations.laptop` (Mac)
  - `nixosConfigurations.nixos` (laptop)
  - `nixosConfigurations.nixos-vm` (VM)
  - shared `stateVersion`, `dotfilesDir`, dev tooling modules, home-manager
- `profiles/`
  - `laptop.nix` – common profile for real machines (GC, base settings)
  - `vm.nix` – lightweight NixOS VM profile (GNOME, small package set)
- `modules/common/`
  - `dev/rust.nix` – rustup + rust dev tooling from nixpkgs (Darwin + NixOS)
  - `dev/haskell.nix` – GHC + cabal + stack + HLS from nixpkgs
  - `home/*` – common home-manager bits (fish, git, dotfiles)
- `modules/darwin/` – nix-darwin system modules:
  - `00-base.nix` – base system, primary user, GC interval
  - `system-packages.nix` – system-wide packages
  - `homebrew.nix` – Homebrew taps, casks, MAS apps
  - `launchd.nix` – user launchd agents (Raycast, Aerospace, OLoveBar)
  - `dev/julia.nix` – Julia via `juliaup` (Darwin only)
- `modules/nixos/` – NixOS system modules:
  - `base.nix` – locale, networking, XDG, base packages
  - `users/` – NixOS users, per-host pieces
  - `desktop/gnome.nix` – GNOME desktop (used on laptop + VM)
- `hosts/`
  - `nixos/` – real NixOS laptop host (fs layout by-label)
  - `nixos-vm/` – VM host config (Parallels)
- `home/`
  - `default.nix` – single home-manager entrypoint for both Darwin + NixOS
- `dotfiles/`
  - `common/` – stuff for `~/.config` used on both platforms (kitty, zed, starship, neofetch)
  - `darwin/` – macOS-specific configs (OLoveBar, Aerospace, tmux)
  - `nixos/` – Linux-specific configs (tmux)
- `secrets/`
  - SOPS + age secrets, managed via `sops-nix`

## Targets

### macOS (nix-darwin)

Build & switch:

```bash
cd ~/Projects/Darwin
sudo darwin-rebuild switch --flake .#laptop --impure
```

- Uses `system.primaryUser = "vietnamveteran"`.
- Home-manager is embedded via `home-manager.darwinModules.home-manager`.
- Homebrew is managed declaratively (taps, brews, casks, MAS apps).
- Rust, Haskell, Julia dev tooling is shared via `modules/common/dev/*` and `modules/darwin/dev/julia.nix`.

### NixOS laptop

On the NixOS laptop:

```bash
sudo nixos-rebuild switch --flake .#nixos --impure
```

- Uses `profiles/laptop.nix` + `hosts/nixos/configuration.nix`.
- GNOME desktop from `modules/nixos/desktop/gnome.nix`.
- Same dev tooling and home-manager layout as on macOS.

### NixOS VM

Inside the VM:

```bash
sudo nixos-rebuild switch --flake .#nixos-vm --impure
```

- Uses `profiles/vm.nix` + `hosts/nixos-vm/configuration.nix`.
- GNOME desktop, lightweight package set (LLVM/clang etc. as needed).

## Home-manager & dotfiles

Home-manager is wired once in `flake.nix` and dispatched via `home/default.nix`:

- Common modules: `modules/common/home/*`
- Darwin-specific: `modules/darwin/home/default.nix`
- NixOS-specific: `modules/nixos/home/default.nix`

Dotfiles:
- `dotfiles/common/*` are linked into `~/.config` via `modules/common/home/dotfiles.nix`
- Darwin-only / NixOS-only configs live under `dotfiles/darwin` and `dotfiles/nixos`

## Secrets (SOPS + age)

Secrets live under `secrets/` and are decrypted at activation time via `sops-nix`:

- Age key: generated once (`make sops-key`) into `~/.config/sops/age/keys.txt`
- `.sops.yaml` (in repo root) defines which secrets are encrypted for which key
- Usage example:

```bash
nix shell nixpkgs#sops -c sops secrets/example.yaml
```

You can then consume secrets from Nix via `sops.secrets.<name>` options.

## Dev examples

There is an example C project under `example/cproject/flake.nix` that shows how to
build and develop C code with this flake as a base.

