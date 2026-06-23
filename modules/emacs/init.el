;;; init.el --- Emacs config: Rust / C / C++ IDE -*- lexical-binding: t; -*-
;;
;; All packages are installed and on `load-path' via Nix
;; (home-manager `programs.emacs.extraPackages'), so `use-package' never
;; downloads anything: `use-package-always-ensure' stays nil.

;;; ---------------------------------------------------------------------------
;;; Core
;;; ---------------------------------------------------------------------------

(require 'use-package)
(setq use-package-always-ensure nil
      use-package-expand-minimally t)

;; Restore a reasonable GC threshold after startup (early-init raised it).
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

(setq-default
 indent-tabs-mode nil
 tab-width 4
 fill-column 100
 truncate-lines t)

(setq inhibit-startup-message t
      ring-bell-function 'ignore
      use-short-answers t
      create-lockfiles nil
      make-backup-files nil
      require-final-newline t
      sentence-end-double-space nil
      scroll-conservatively 101
      scroll-margin 3)

(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)   ; match the Neovim setup
(column-number-mode 1)
(global-hl-line-mode 1)
(delete-selection-mode 1)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)
(electric-pair-mode 1)
(show-paren-mode 1)

;; UTF-8 everywhere.
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

;; Keep state files out of the config dir.
(use-package no-littering
  :config
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))

;;; ---------------------------------------------------------------------------
;;; macOS / environment
;;; ---------------------------------------------------------------------------

;; GUI Emacs on macOS does not inherit the shell PATH, so rust-analyzer,
;; clangd, cargo, etc. would not be found. Import it from the login shell.
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (setq exec-path-from-shell-arguments '("-l"))
  (dolist (var '("PATH" "CARGO_HOME" "RUSTUP_HOME" "RUST_SRC_PATH" "LIBRARY_PATH"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

;; Ensure ~/.cargo/bin is on exec-path even without a login shell.
(let ((cargo-bin (expand-file-name "~/.cargo/bin")))
  (when (file-directory-p cargo-bin)
    (add-to-list 'exec-path cargo-bin)
    (setenv "PATH" (concat cargo-bin path-separator (getenv "PATH")))))

;; macOS modifier keys: Command = Meta, Option stays for special chars.
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'none))

;;; ---------------------------------------------------------------------------
;;; Appearance (gruvbox hard, to match Neovim)
;;; ---------------------------------------------------------------------------

(use-package gruvbox-theme
  :config (load-theme 'gruvbox-dark-hard t))

(let ((font "JetBrainsMono Nerd Font"))
  (when (member font (font-family-list))
    (set-face-attribute 'default nil :family font :height 140)))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package which-key
  :config (which-key-mode 1))

;;; ---------------------------------------------------------------------------
;;; Completion / navigation stack
;;; ---------------------------------------------------------------------------

(use-package vertico
  :init (vertico-mode 1)
  :config (setq vertico-cycle t))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package consult
  :bind (("C-s"   . consult-line)
         ("C-x b" . consult-buffer)
         ("M-y"   . consult-yank-pop)
         ("M-g g" . consult-goto-line)
         ("M-g i" . consult-imenu)
         ("M-s r" . consult-ripgrep)))

(use-package yasnippet
  :config (yas-global-mode 1))
(use-package yasnippet-snippets :after yasnippet)

;; In-buffer completion popup.
(use-package corfu
  :init (global-corfu-mode 1)
  :config
  (setq corfu-auto t
        corfu-auto-prefix 1
        corfu-auto-delay 0.1
        corfu-cycle t
        corfu-preselect 'prompt)
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package kind-icon
  :after corfu
  :config
  (setq kind-icon-default-face 'corfu-default)
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

;;; ---------------------------------------------------------------------------
;;; Tree-sitter (grammars provided by Nix, symlinked into ~/.config/emacs)
;;; ---------------------------------------------------------------------------

(add-to-list 'treesit-extra-load-path
             (expand-file-name "tree-sitter" user-emacs-directory))

(setq treesit-font-lock-level 4)

;; Prefer the tree-sitter major modes when grammars are available.
(dolist (mapping '((c-mode       . c-ts-mode)
                   (c++-mode     . c++-ts-mode)
                   (c-or-c++-mode . c-or-c++-ts-mode)
                   (rust-mode    . rust-ts-mode)
                   (cmake-mode   . cmake-ts-mode)
                   (toml-mode    . toml-ts-mode)
                   (json-mode    . json-ts-mode)
                   (js-mode      . js-ts-mode)
                   (python-mode  . python-ts-mode)))
  (add-to-list 'major-mode-remap-alist mapping))

;;; ---------------------------------------------------------------------------
;;; LSP
;;; ---------------------------------------------------------------------------

(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  ;; Let Corfu handle completion instead of company.
  (setq lsp-completion-provider :none)
  :hook ((c-ts-mode    . lsp-deferred)
         (c++-ts-mode  . lsp-deferred)
         (c-or-c++-ts-mode . lsp-deferred)
         (rust-ts-mode . lsp-deferred)
         (lsp-completion-mode
          . (lambda ()
              (setf (alist-get 'lsp-capf completion-category-defaults)
                    '((styles . (orderless flex)))))))
  :commands (lsp lsp-deferred)
  :config
  (setq lsp-idle-delay 0.1
        lsp-log-io nil
        lsp-headerline-breadcrumb-enable t
        lsp-eldoc-render-all nil
        lsp-enable-snippet t
        lsp-modeline-code-actions-enable t
        lsp-signature-auto-activate t
        lsp-inlay-hint-enable t)

  ;; ---- rust-analyzer: maximal feature set ----
  (setq lsp-rust-analyzer-cargo-watch-command "clippy"
        lsp-rust-analyzer-cargo-watch-enable t
        lsp-rust-analyzer-check-all-targets t
        lsp-rust-analyzer-proc-macro-enable t
        lsp-rust-analyzer-experimental-proc-attr-macros t
        lsp-rust-analyzer-cargo-load-out-dirs-from-check t
        lsp-rust-analyzer-display-chaining-hints t
        lsp-rust-analyzer-display-parameter-hints t
        lsp-rust-analyzer-display-closure-return-type-hints t
        lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial"
        lsp-rust-analyzer-binding-mode-hints t
        lsp-rust-analyzer-closing-brace-hints t
        lsp-rust-analyzer-server-display-inlay-hints t
        lsp-rust-analyzer-import-merge-behaviour "last"
        lsp-rust-analyzer-completion-add-call-parenthesis t)

  ;; ---- clangd: rich C/C++ experience ----
  (setq lsp-clients-clangd-args
        '("--header-insertion=iwyu"
          "--completion-style=detailed"
          "--background-index"
          "--clang-tidy"
          "--all-scopes-completion"
          "--pch-storage=memory"
          "-j=4"
          "--header-insertion-decorators=0")))

(use-package lsp-ui
  :after lsp-mode
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-doc-enable t
        lsp-ui-doc-show-with-cursor t
        lsp-ui-doc-position 'at-point
        lsp-ui-sideline-enable t
        lsp-ui-sideline-show-hover nil
        lsp-ui-sideline-show-code-actions t))

(use-package consult-lsp
  :after (lsp-mode consult)
  :bind (:map lsp-mode-map
              ([remap xref-find-apropos] . consult-lsp-symbols)))

;;; ---------------------------------------------------------------------------
;;; Diagnostics
;;; ---------------------------------------------------------------------------

(use-package flycheck
  :init (global-flycheck-mode 1)
  :config (setq flycheck-check-syntax-automatically '(save mode-enabled)))

;;; ---------------------------------------------------------------------------
;;; Debugging (DAP: lldb for Rust / C / C++)
;;; ---------------------------------------------------------------------------

(use-package dap-mode
  :after lsp-mode
  :config
  (dap-auto-configure-mode 1)
  (require 'dap-lldb)
  (require 'dap-cpptools)
  ;; Use lldb-dap (provided via the Nix module's home packages / PATH).
  (setq dap-lldb-debug-program '("lldb-dap"))
  (dap-register-debug-template
   "Rust/C++ :: Run (lldb)"
   (list :type "lldb"
         :request "launch"
         :name "Rust/C++ :: Run (lldb)"
         :gdbpath "rust-lldb"
         :target nil
         :cwd nil)))

;;; ---------------------------------------------------------------------------
;;; Rust
;;; ---------------------------------------------------------------------------

(use-package rustic
  :mode ("\\.rs\\'" . rustic-mode)
  :config
  (setq rustic-lsp-client 'lsp-mode
        rustic-cargo-bin "cargo"
        rustic-format-on-save t
        ;; Force a nightly rustfmt (matches the Neovim setup). The rustup
        ;; `rustfmt' shim forwards the `+nightly' toolchain selector.
        rustic-rustfmt-args "+nightly"
        rustic-rustfmt-bin "rustfmt")
  ;; rustic-mode derives from rust-ts-mode when tree-sitter is available.
  (add-hook 'rustic-mode-hook
            (lambda () (setq-local buffer-save-without-query t))))

;;; ---------------------------------------------------------------------------
;;; C / C++
;;; ---------------------------------------------------------------------------

(use-package clang-format
  :commands (clang-format-buffer clang-format-region))

(defun my/c-c++-format-on-save ()
  "Format C/C++ buffers with clang-format before saving."
  (when (derived-mode-p 'c-ts-mode 'c++-ts-mode 'c-mode 'c++-mode)
    (clang-format-buffer)))

(dolist (hook '(c-ts-mode-hook c++-ts-mode-hook))
  (add-hook hook
            (lambda ()
              (setq-local c-ts-mode-indent-offset 4
                          indent-tabs-mode nil)
              (add-hook 'before-save-hook #'my/c-c++-format-on-save nil t))))

(use-package cmake-mode
  :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'"))

;;; ---------------------------------------------------------------------------
;;; Project / VCS / misc languages
;;; ---------------------------------------------------------------------------

(use-package magit
  :bind ("C-x g" . magit-status))

(use-package editorconfig
  :config (editorconfig-mode 1))

(use-package nix-mode  :mode "\\.nix\\'")
(use-package toml-mode :mode "\\.toml\\'")
(use-package markdown-mode :mode "\\.md\\'")

;; Built-in project.el is sufficient with the above.
(setq project-vc-extra-root-markers '("Cargo.toml" "compile_commands.json" "CMakeLists.txt"))

;;; init.el ends here
