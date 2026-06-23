;;; early-init.el --- Pre-frame, pre-package startup tuning -*- lexical-binding: t; -*-

;; Packages are provided by Nix (home-manager programs.emacs.extraPackages),
;; so disable the built-in package.el at startup to avoid duplicate load paths.
(setq package-enable-at-startup nil)

;; Raise the GC ceiling during startup; restored to a sane value in init.el.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Avoid a flash of unstyled UI.
(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t
      inhibit-splash-screen t)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; Silence native-comp warnings (packages are byte-compiled by Nix anyway).
(setq native-comp-async-report-warnings-errors 'silent)

;;; early-init.el ends here
