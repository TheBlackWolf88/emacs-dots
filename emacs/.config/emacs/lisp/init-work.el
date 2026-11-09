;;; init-work.el --- Work-specific configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(setq url-proxy-services '(("https" . "127.0.0.1:3128")
                           ("http" . "127.0.0.1:3128")))

(exec-path-from-shell-copy-envs
 '("DOTNET_ROOT" "CLAUDE_CODE_USE_FOUNDRY"
   "ANTHROPIC_FOUNDRY_BASE_URL" "ANTHROPIC_FOUNDRY_API_KEY"))

;; AFTER the initialize call
;; Appended, not prepended: /home/linuxbrew/.linuxbrew/bin ships its own
;; `dotnet' (a different SDK version than DOTNET_ROOT/~/.dotnet). Prepending
;; it shadowed the real dotnet for every child process, including the
;; `dotnet restore'/design-time builds roslyn-language-server runs
;; internally -- which silently broke diagnostics (no errors, just an
;; empty result) without any visible error anywhere in the LSP traffic.
(dolist (dir (list "/home/linuxbrew/.linuxbrew/bin"
                   (expand-file-name "~/.local/share/pnpm/bin")
                   (expand-file-name "~/.local/bin")))
  (when (file-directory-p dir)
    (add-to-list 'exec-path dir t)
    (setenv "PATH" (concat (getenv "PATH") path-separator dir))))

(use-package jira
  :config
  (setq jira-base-url "https://obbdigitaltransformationtechnology.atlassian.net")
  (setq jira-token-is-personal-access-token nil)
  (setq jira-api-version 3))

(provide 'init-work)
;;; init-work.el ends here
