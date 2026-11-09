;;; init-completion.el --- Completion and minibuffer UI -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

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
  ;; corfu's own maintainer warns against prefix < 2 ("high load for
  ;; Emacs"); against an LSP completion source as heavy as C#'s, 3
  ;; (corfu's current upstream default) is the sane floor.
  (corfu-auto-prefix 3))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t))

;;; Consult

(use-package consult
  :ensure t
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  (setq consult-preview-key '(:debounce 0.2 any))
  (setq consult-narrow-key "<"))

(use-package consult-eglot
  :ensure t
  :after (consult eglot))

(define-prefix-command 'consult-map)
(global-set-key (kbd "C-c C-s") 'consult-map)

(define-key consult-map (kbd "p")
            (lambda ()
              (interactive)
                (consult-find (project-root (project-current t)))))

(define-key consult-map (kbd "r")
            (lambda ()
              (interactive)
              (consult-ripgrep (project-root (project-current t)))))

(define-key consult-map (kbd "s")
            (lambda ()
              (interactive)
              (if (bound-and-true-p eglot--managed-mode)
                  (consult-eglot-symbols)
                (consult-imenu))))

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "C-c C-s"   "search"
    "C-c C-s p" "find file"
    "C-c C-s r" "ripgrep"
    "C-c C-s s" "symbols"))

(provide 'init-completion)
;;; init-completion.el ends here
