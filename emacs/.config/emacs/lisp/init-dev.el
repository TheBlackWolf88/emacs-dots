;;; init-dev.el --- Development tools and language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

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


(setq project-vc-extra-root-markers
      '("*.sln" "*.slnx" "go.mod"))

(add-hook 'prog-mode-hook (lambda () (setq truncate-lines t)))

(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package magit
  :ensure t
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-diff-refine-hunk t)          ; word-level diff highlighting in current hunk
  (magit-save-repository-buffers 'dontask))
 
(use-package vterm
  :ensure t)

;;;; LSP

(use-package mason
  :ensure t
   :custom
  (mason-registries
   '(("mason" . "https://github.com/mason-org/mason-registry/releases/latest/download/registry.json.zip")
     ("crashdummyy" . "https://github.com/Crashdummyy/mason-registry/releases/latest/download/registry.json.zip")))
  :config
  (mason-setup))

(mason-setup
  (dolist (pkg '("basedpyright" "clangd" "rust_analyzer" "gopls" "ruff"
                 "csharp-language-server" "roslyn-language-server" "netcoredbg"))
    (unless (mason-installed-p pkg)
      (ignore-errors (mason-install pkg)))))

(use-package flycheck
  :ensure t
  :config
  (add-hook 'after-init-hook #'global-flycheck-mode))

(use-package eglot
  :ensure t                     ; pull the GNU ELPA version (pull-diagnostics support),
                                 ; not Emacs's older bundled one -- see init-package.el
  :hook ((python-ts-mode . eglot-ensure)
         (c-ts-mode . eglot-ensure)
         (c++-ts-mode . eglot-ensure)
         (rust-ts-mode . eglot-ensure)
         (tsx-ts-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
	 (csharp-ts-mode . eglot-ensure))
  :custom
  ;; Full-format JSON-RPC logging is pure overhead against a chatty C#
  ;; server; turn it off (M-x eglot-events-buffer toggles it back on ad hoc).
  (eglot-events-buffer-config '(:size 0)))

(defun my/eglot-csharp-contact (&rest _)
  "Prefer Roslyn LS, then csharp-ls, then OmniSharp.
Without this, `eglot-server-programs' default alternatives list tries
\"omnisharp\" before \"csharp-ls\", so OmniSharp (the slowest, MSBuild-based
option) silently wins whenever both are on PATH, as they are via mason."
  (cond
   ((executable-find "roslyn-language-server")
    (list "roslyn-language-server"
          "--logLevel" "Information"
          "--extensionLogDirectory" (expand-file-name "roslyn-logs/" user-emacs-directory)
          "--stdio"
          "--autoLoadProjects"))
   ((executable-find "csharp-ls") (list "csharp-ls"))
   (t (funcall (eglot-alternatives '(("omnisharp" "-lsp") ("OmniSharp" "-lsp")))))))

(defun my/eglot-roslyn-open-project (server)
  "Explicitly load the solution/project for a freshly connected Roslyn LS.
Verified empirically: --autoLoadProjects alone never fires
`workspace/projectInitializationComplete' (waited 90s), so the server
never loads the project and never produces diagnostics.  It only loads
via the same custom `solution/open'/`project/open' notifications VS
Code's C# extension sends, which eglot has no built-in notion of."
  (when (memq 'csharp-ts-mode (eglot--major-modes server))
    (let* ((root (project-root (eglot--project server)))
           (sln (car (directory-files root t "\\.slnx?\\'"))))
      (if sln
          (jsonrpc-notify server :solution/open
                           (list :solution (concat "file://" (expand-file-name sln))))
        (when-let* ((csprojs (seq-remove
                               (lambda (f) (string-match-p "/\\(bin\\|obj\\)/" f))
                               (directory-files-recursively root "\\.csproj\\'"))))
          (jsonrpc-notify server :project/open
                           (list :projects
                                 (vconcat (mapcar (lambda (f)
                                                     (concat "file://" (expand-file-name f)))
                                                   csprojs)))))))))

(with-eval-after-load 'eglot
  ;; razor-mode is grouped in here (not a separate entry) so that opening a
  ;; .razor/.cshtml file in a project that already has a connected Roslyn
  ;; server attaches to that SAME connection instead of spawning a second
  ;; one -- required for Razor "cohosting" (cross-file analysis between
  ;; .razor and .cs) to actually work.
  (add-to-list 'eglot-server-programs
               (cons '(csharp-mode csharp-ts-mode (razor-mode :language-id "aspnetcorerazor"))
                     #'my/eglot-csharp-contact))
  (add-hook 'eglot-connect-hook #'my/eglot-roslyn-open-project)
  (define-key eglot-mode-map (kbd "C-c h") 'eldoc-doc-buffer)      ; hover-style popup
  (define-key eglot-mode-map (kbd "C-c C-d c") 'eglot-find-declaration)
  (define-key eglot-mode-map (kbd "C-c C-g i") 'eglot-find-implementation)
  (define-key eglot-mode-map (kbd "C-c C-t d") 'eglot-find-typeDefinition)
  (define-key eglot-mode-map (kbd "C-c C-r n") 'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c C-c a") 'eglot-code-actions)
  (define-key eglot-mode-map (kbd "C-c C-g d") 'xref-find-definitions)
  (define-key eglot-mode-map (kbd "C-c C-v r") 'xref-find-references))

(global-set-key (kbd "C-o") #'xref-go-back)
(global-set-key (kbd "C-M-o") #'xref-go-forward)

(add-to-list 'auto-mode-alist '("\\.csproj\\'" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.slnx\\'" . nxml-mode))

(add-hook 'csharp-ts-mode-hook
          (lambda ()
            (setq-local tab-width 4
                        indent-tabs-mode nil)))

;;;; Snippets

(use-package yasnippet
  :ensure t
  :config (yas-global-mode 1))

(defun my/csharp-root-namespace (csproj)
  "Root namespace for CSPROJ: its <RootNamespace>, or its filename.
Mirrors MSBuild's own default (RootNamespace defaults to the project
file's name when the element is absent)."
  (or (with-temp-buffer
        (insert-file-contents csproj)
        (when (re-search-forward "<RootNamespace>\\([^<]+\\)</RootNamespace>" nil t)
          (match-string 1)))
      (file-name-base csproj)))

(defun my/csharp-namespace-from-file ()
  "Namespace for the current buffer's file, derived from its nearest .csproj.
Dot-joins the root namespace with the file's directory path relative to
the .csproj, the same convention MSBuild uses for SDK-style projects."
  (let* ((csproj (my-nearest-csproj))
         (root-ns (my/csharp-root-namespace csproj))
         (rel-dir (directory-file-name
                   (file-relative-name (file-name-directory (buffer-file-name))
                                       (file-name-directory csproj)))))
    (if (string= rel-dir ".")
        root-ns
      (mapconcat #'identity (cons root-ns (split-string rel-dir "/" t)) "."))))

(defun my/csharp-new-file-template ()
  "On a new, empty .cs file, ask what kind of type it defines and scaffold it."
  (interactive)
  (let ((kind (completing-read "Type: " '("Class" "Interface" "Record" "Enum") nil t)))
    (insert (format "namespace %s;\n\n" (my/csharp-namespace-from-file)))
    (yas-expand-snippet (yas-lookup-snippet kind 'csharp-ts-mode))))

(with-eval-after-load 'autoinsert
  (setq auto-insert-query nil)        ; skip "Perform auto-insertion? (y/n)"
  (define-auto-insert "\\.cs\\'" #'my/csharp-new-file-template))
(auto-insert-mode 1)

 ;;; Avalonia
 
 (define-derived-mode axaml-mode nxml-mode "AXAML"
   "Major mode for Avalonia AXAML files, tree-sitter XML backend.")
 
 (add-to-list 'auto-mode-alist '("\\.axaml\\'" . axaml-mode))
 
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(axaml-mode . ("avalonia-ls"))))
 
(add-hook 'axaml-mode-hook #'eglot-ensure)

(add-to-list 'exec-path (expand-file-name "~/.local/bin/"))

;;; Razor / Blazor

(use-package web-mode
  :ensure t)

(define-derived-mode razor-mode web-mode "Razor"
  "Major mode for Razor/Blazor .razor and .cshtml files.
A distinct mode (rather than using `web-mode' directly) so eglot only
auto-connects for actual Razor files, not every other web-mode buffer.
web-mode's own `.razor'/`.cshtml' engine auto-detection takes care of
getting the embedded-C# fontification right.")

(add-to-list 'auto-mode-alist '("\\.razor\\'" . razor-mode))
(add-to-list 'auto-mode-alist '("\\.cshtml\\'" . razor-mode))

(add-hook 'razor-mode-hook #'eglot-ensure)

;;; Bicep

(use-package bicep-ts-mode
  :ensure t
  :vc ( :url "https://github.com/josteink/bicep-ts-mode"
        :rev :newest))

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
  (defun my/dape-kill-compile-buffer (buffer)
    "Kill dape's compile BUFFER, bypassing the running-process query."
    (when (buffer-live-p buffer)
      (when-let ((proc (get-buffer-process buffer)))
	(set-process-query-on-exit-flag proc nil))
      (kill-buffer buffer)))

  (add-hook 'dape-compile-hook #'my/dape-kill-compile-buffer)
  

 
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
               :console "internalConsole"
               :internalConsoleOptions "neverOpen"
               :suppressJITOptimizations t
               :requireExactSource nil
               :justMyCode t
	       :env (:DISPLAY ":0")
               :cwd (lambda () (project-root (project-current)))
               :program (lambda () (my-dotnet-program))))

)

(provide 'init-dev)
;;; init-dev.el ends here
