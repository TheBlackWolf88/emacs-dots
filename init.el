;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;;hey guys guy here

;;; Code:

;;;; Use-package
(require 'package)
(require 'use-package-ensure)
(setq use-package-always-ensure t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;;;; Sets

(setq inhibit-startup-message t) ; Don't show the splash screen
(setq visible-bell nil)            ; Flash when the bell rings
;; Turn off some unneeded UI elements
(menu-bar-mode -1)  ; Leave this one on if you're a beginner!
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Display line numbers in every buffer
(column-number-mode)
(global-display-line-numbers-mode 1)

;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(add-to-list 'display-buffer-alist
             '("\\`\\*\\(Warnings\\|Compile-Log\\)\\*\\'"
               (display-buffer-no-window)
               (allow-no-window . t)))

;; Load the Modus Vivendi dark theme
(load-theme 'modus-vivendi t)

(recentf-mode 1)

;; Save what you enter into minibuffer prompts
(setq history-length 25)
(savehist-mode 1)

;; Remember and restore the last cursor location of opened files
(save-place-mode 1)

;; Move customization variables to a separate file and load it
(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)

;; Don't pop up UI dialogs when prompting
(setq use-dialog-box nil)

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)

;; Revert Dired and other buffers
(setq global-auto-revert-non-file-buffers t)

(let ((mono-spaced-font "Iosevka")
      (proportionately-spaced-font "Sans"))
  (set-face-attribute 'default nil :family mono-spaced-font :height 130)
  (set-face-attribute 'fixed-pitch nil :family mono-spaced-font :height 1.0)
  (set-face-attribute 'variable-pitch nil :family proportionately-spaced-font :height 1.0))

(global-set-key (kbd "C-p") (lambda () (interactive) (forward-line -5)))
(global-set-key (kbd "C-n") (lambda () (interactive) (forward-line 5)))
(global-set-key (kbd "C-S-p") (lambda () (interactive) (forward-line -1)))
(global-set-key (kbd "C-S-n") (lambda () (interactive) (forward-line 1)))



;;;; Tree-Sitter
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))
 
;;;; Minor tools

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

;;;; LSP

(use-package mason
  :ensure t
  :config
  (mason-setup))

(mason-setup
  (dolist (pkg '("basedpyright" "clangd" "rust_analyzer" "gopls" "ruff" "csharp-language-server" "netcoredbg"))
    (unless (mason-installed-p pkg)
      (ignore-errors (mason-install pkg)))))

(use-package flycheck
  :ensure t
  :config
  (add-hook 'after-init-hook #'global-flycheck-mode))

(use-package eglot
  :hook ((python-ts-mode . eglot-ensure)
         (c-ts-mode . eglot-ensure)
         (c++-ts-mode . eglot-ensure)
         (rust-ts-mode . eglot-ensure)
         (tsx-ts-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
	 (csharp-ts-mode . eglot-ensure)))

(with-eval-after-load 'eglot
  (define-key eglot-mode-map (kbd "C-c h") 'eldoc-doc-buffer)      ; hover-style popup
  (define-key eglot-mode-map (kbd "C-c C-d c") 'eglot-find-declaration)
  (define-key eglot-mode-map (kbd "C-c C-g i") 'eglot-find-implementation)
  (define-key eglot-mode-map (kbd "C-c C-t d") 'eglot-find-typeDefinition)
  (define-key eglot-mode-map (kbd "C-c C-r n") 'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c C-c a") 'eglot-code-actions)
  (define-key eglot-mode-map (kbd "C-c C-g d") 'xref-find-definitions)
  (define-key eglot-mode-map (kbd "C-c C-v r") 'xref-find-references))

(global-set-key (kbd "C-o") #'xref-go-back)
(global-set-key (kbd "C-i") #'xref-go-forward)

(add-to-list 'auto-mode-alist '("\\.csproj\\'" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.slnx\\'" . nxml-mode))

;;;; Completion / UI

(use-package vertico
  :init (vertico-mode))

(use-package corfu
  :init (global-corfu-mode)
  :bind (:map corfu-map
              ("C-y" . corfu-insert))
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 1))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t))

;;;; Dape / Debugger

(use-package dape
  :hook
  ;; Save breakpoints on quit
  (kill-emacs . dape-breakpoint-save)
  ;; Load breakpoints on startup
  (after-init . dape-breakpoint-load)

  :custom
  ;; Turn on global bindings for setting breakpoints with mouse
  (dape-breakpoint-global-mode +1)

  ;; Info buffers to the right
  (dape-buffer-window-arrangement 'right)
  
  :config
  ;; Pulse source line (performance hit)
  (add-hook 'dape-display-source-hook #'pulse-momentary-highlight-one-line)

  ;; Save buffers on startup, useful for interpreted languages
  (add-hook 'dape-start-hook (lambda () (save-some-buffers t t)))

  ;; Kill compile buffer on build success
  (add-hook 'dape-compile-hook #'kill-buffer)
  )

;; For a more ergonomic Emacs and `dape' experience
(use-package repeat
  :custom
  (repeat-mode +1))

;; Left and right side windows occupy full frame height
(use-package emacs
  :custom
  (window-sides-vertical t))
(provide 'init)

;;; init.el ends here
