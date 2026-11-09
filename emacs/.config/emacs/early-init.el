;;; early-init.el --- runs before init.el and GUI setup -*- lexical-binding: t; -*-

;; Faster startup: avoid garbage collection while loading, restore afterwards
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 64 1024 1024))))

;; You call (package-initialize) in init.el yourself, so stop Emacs from
;; doing it a second time before init.el
(setq package-enable-at-startup nil)

;; Disable UI elements before the first frame is drawn (no flicker)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; Don't resize the frame when fonts or UI change during startup
(setq frame-inhibit-implied-resize t)

;; Skip the startup screen early
(setq inhibit-startup-screen t)

;; Prefer newer .el files over stale .elc
(setq load-prefer-newer t)
