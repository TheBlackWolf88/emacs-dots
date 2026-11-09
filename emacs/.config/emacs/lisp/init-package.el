;;; init-package.el --- Package management setup -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'package)
(require 'use-package-ensure)
(setq use-package-always-ensure t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; `package-installed-p' treats Emacs's bundled eglot as already
;; "installed", so plain `:ensure t' is a no-op for it and `package-install'
;; ignores it too unless `package-install-upgrade-built-in' is set -- so
;; without both of these you get stuck on Emacs's bundled eglot, which has
;; no pull-diagnostics support, instead of GNU ELPA's newer one.
(setq package-install-upgrade-built-in t)
(unless (assq 'eglot package-alist)
  (ignore-errors (package-refresh-contents))
  (package-install 'eglot))

;; Keep gc-cons-threshold high while idle, drop it low while active, so
;; GC doesn't stall typing while a chatty LSP server is parsing/replying.
(use-package gcmh
  :ensure t
  :init (gcmh-mode 1)
  :custom
  (gcmh-high-cons-threshold (* 128 1024 1024)))

(provide 'init-package)
;;; init-package.el ends here
