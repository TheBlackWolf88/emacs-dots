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

(delete-selection-mode 1)

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

(setq project-vc-extra-root-markers
      '("*.sln" "*.slnx" "*.csproj" "go.mod"))

;;;; Custom functions

(defun my-nearest-csproj ()
  "Find the .csproj closest to the current buffer."
  (let ((dir (locate-dominating-file
              (or (buffer-file-name) default-directory)
              (lambda (d) (directory-files d nil "\\.csproj\\'")))))
    (when dir
      (car (directory-files dir t "\\.csproj\\'")))))

(defun my-dotnet-program ()
  "Find the built Debug dll matching the nearest .csproj, or error clearly."
  (let* ((csproj (my-nearest-csproj))
         (_ (unless csproj (user-error "No .csproj found above %s" default-directory)))
         (proj-dir (file-name-directory csproj))
         (name (file-name-base csproj))
         (candidates (seq-filter
                      (lambda (dll)
                        (and (string-match-p "/bin/Debug/" dll)
                             (string= (file-name-base dll) name)
                             (file-exists-p (concat (file-name-sans-extension dll)
                                                     ".runtimeconfig.json"))))
                      (directory-files-recursively proj-dir "\\.dll$")))
         (newest (car (sort candidates
                             (lambda (a b) (file-newer-than-file-p a b))))))
    (or newest
        (user-error "No built Debug dll for %s — build the project first" name))))

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

(use-package vterm
    :ensure t)

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
  (message "HEYOOOOO")
  ;; Pulse source line (performance hit)
  (add-hook 'dape-display-source-hook #'pulse-momentary-highlight-one-line)

  ;; Save buffers on startup, useful for interpreted languages
  (add-hook 'dape-start-hook (lambda () (save-some-buffers t t)))

  ;; Kill compile buffer on build success
  (add-hook 'dape-compile-hook #'kill-buffer)

 
  (add-to-list 'dape-configs
             `(dotnetdbg
               modes (csharp-mode csharp-ts-mode)
               ensure dape-ensure-command
               command "netcoredbg"
               command-args ("--interpreter=vscode")
               command-cwd (lambda () (project-root (project-current)))
               compile (lambda () (concat "dotnet build \""
                                           (file-name-directory (my-nearest-csproj))
                                           "\""))
               :type "coreclr"
               :request "launch"
               :console "externalTerminal"
               :internalConsoleOptions "neverOpen"
               :suppressJITOptimizations t
               :requireExactSource nil
               :justMyCode t
               :cwd (lambda () (project-root (project-current)))
               :program (lambda () (my-dotnet-program))))
  
)

;; For a more ergonomic Emacs and `dape' experience
(use-package repeat
  :custom
  (repeat-mode +1))

;;; GPT

(use-package gptel
  :ensure t
  :bind (("C-c g g" . gptel)                 ;; open a chat buffer
         ("C-c g s" . gptel-send)             ;; send region/prompt
         ("C-c g m" . gptel-menu)             ;; transient menu (model, params, etc.)
         ("C-c g r" . gptel-rewrite))         ;; rewrite region in place
  :config
  ;; Define the local llama.cpp server as a backend
  (gptel-make-openai "llama-cpp-local"
    :host "localhost:8080"
    :protocol "http"
    :endpoint "/v1/chat/completions"
    :stream t
    :models '("qwen2.5-coder-14b-instruct"))  ;; name is cosmetic, server ignores it

  ;; Make it the default backend/model on startup
  (setq gptel-model "qwen2.5-coder-14b-instruct"
        gptel-backend (gptel-get-backend "llama-cpp-local"))

  ;; Optional: directory-local or per-project system prompt for C#/.NET work
  (setq gptel-directives
        '((default . "You are a terse, precise coding assistant. Prefer idiomatic solutions and avoid unnecessary complexity.")
          (csharp . "You are an expert C#/.NET assistant. Follow idiomatic C# conventions, favor minimal solutions, and call out anti-patterns when relevant."))))

;; Left and right side windows occupy full frame height
(use-package emacs
  :custom
  (window-sides-vertical t))
(provide 'init)

;;; init.el ends here
