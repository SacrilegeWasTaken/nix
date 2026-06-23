# Emacs as a Rust/C/C++ IDE, fully Nix-managed (home-manager).
# Package set and config (init.el) are pinned through Nix, mirroring the
# Neovim/nixvim approach: nothing is downloaded by package.el at runtime.
#
# NOTE: "remacs" (the Rust rewrite of Emacs) was archived in 2021 and is not
# packaged in nixpkgs, so this uses standard Emacs 30 (emacs-macport on macOS
# for a native Cocoa GUI, emacs-pgtk on Linux).
{ config, pkgs, lib, ... }:

let
  emacsPkg = if pkgs.stdenv.isDarwin then pkgs.emacs-macport else pkgs.emacs-pgtk;
  epkgs = pkgs.emacsPackagesFor emacsPkg;
  treesitGrammars = epkgs.treesit-grammars.with-all-grammars;
in
{
  programs.emacs = {
    enable = true;
    package = emacsPkg;
    extraPackages = ep: with ep; [
      use-package
      no-littering
      exec-path-from-shell

      # Appearance
      gruvbox-theme
      rainbow-delimiters
      which-key

      # Completion / navigation
      vertico
      orderless
      marginalia
      consult
      corfu
      cape
      kind-icon
      yasnippet
      yasnippet-snippets

      # LSP
      lsp-mode
      lsp-ui
      consult-lsp
      flycheck

      # Debugging
      dap-mode

      # Rust
      rustic

      # C / C++
      clang-format
      cmake-mode

      # Misc languages / VCS / project
      magit
      editorconfig
      nix-mode
      toml-mode
      markdown-mode
    ];
  };

  # External tools the LSP servers / debugger need on PATH.
  # rust-analyzer/rustfmt come from rustup (modules/common/dev/rust.nix);
  # clangd/clang-format come from clang-tools (darwin system packages).
  home.packages = with pkgs; [
    lldb # lldb-dap for dap-mode
    cmake
    ripgrep # consult-ripgrep
  ];

  # init.el + early-init.el (Emacs 30 honours the XDG location).
  xdg.configFile = {
    "emacs/early-init.el".source = ./early-init.el;
    "emacs/init.el".source = ./init.el;
    # Tree-sitter grammars compiled by Nix; init.el adds this to
    # treesit-extra-load-path.
    "emacs/tree-sitter".source = "${treesitGrammars}/lib";
  };
}
