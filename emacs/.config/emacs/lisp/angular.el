;;; angular.el --- Angular setup for Emacs (Eglot + tree-sitter)  -*- lexical-binding: t; -*-
;;;; Tree-sitter grammars
(setq treesit-language-source-alist
      '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "typescript/src")
        (tsx        "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "tsx/src")
        (html       "https://github.com/tree-sitter/tree-sitter-html" "v0.23.2")
        (css        "https://github.com/tree-sitter/tree-sitter-css" "v0.23.1")
        (json       "https://github.com/tree-sitter/tree-sitter-json" "v0.24.8")))
;; Install missing ones with: M-x treesit-install-language-grammar
 
(add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.component\\.html\\'" . html-ts-mode))
(add-to-list 'auto-mode-alist '("\\.scss\\'" . css-ts-mode))
 
;;;; Eglot: ngserver inside Angular projects, plain tsserver elsewhere
(defun my/angular-project-p ()
  (when-let ((root (locate-dominating-file default-directory "angular.json")))
    root))
 
(defun my/ts-server-contact (&optional _interactive)
  "Return the server command: Angular LS in Angular workspaces, else tsserver wrapper."
  (if-let ((root (my/angular-project-p)))
      (let ((nm (expand-file-name "node_modules" root)))
        `("ngserver" "--stdio"
          "--tsProbeLocations" ,nm
          "--ngProbeLocations" ,nm))
    '("typescript-language-server" "--stdio")))
 
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((typescript-ts-mode tsx-ts-mode html-ts-mode) . my/ts-server-contact)))
 
(dolist (hook '(typescript-ts-mode-hook html-ts-mode-hook))
  (add-hook hook (lambda ()
                   (when (my/angular-project-p)
                     (eglot-ensure)))))
 
;;;; Formatting (Prettier) on save
(use-package apheleia
  :ensure t
  :hook ((typescript-ts-mode html-ts-mode css-ts-mode json-ts-mode) . apheleia-mode))

;; Use 2-space indentation, not tabs. `indent-tabs-mode' defaults to t in
;; Emacs, and apheleia's prettier formatters pass `--use-tabs' whenever it's
;; non-nil -- which overrides .prettierrc's "useTabs": false on every save.
(dolist (hook '(typescript-ts-mode-hook tsx-ts-mode-hook html-ts-mode-hook
                css-ts-mode-hook json-ts-mode-hook))
  (add-hook hook (lambda ()
                   (setq-local indent-tabs-mode nil
                               tab-width 2))))
(setq-default typescript-ts-mode-indent-offset 2
              css-ts-mode-indent-offset 2
              json-ts-mode-indent-offset 2)
 
;;;; Handy: jump between component .ts / .html / .scss / .spec.ts
(defun my/ng-toggle-file (ext)
  "Visit the sibling file of the current Angular component with EXT."
  (let* ((base (file-name-sans-extension
                (file-name-sans-extension (buffer-file-name))))
         (target (concat base ext)))
    (if (file-exists-p target)
        (find-file target)
      (user-error "No %s" target))))
 
(defun my/ng-ts ()   (interactive) (my/ng-toggle-file ".ts"))
(defun my/ng-html () (interactive) (my/ng-toggle-file ".html"))
(defun my/ng-css ()  (interactive) (my/ng-toggle-file ".scss"))
(defun my/ng-spec () (interactive)
  (my/ng-toggle-file ".spec.ts"))
 
;(global-set-key (kbd "C-c a t") #'my/ng-ts)
;(global-set-key (kbd "C-c a h") #'my/ng-html)
;; (global-set-key (kbd "C-c a s") #'my/ng-css)
;; (global-set-key (kbd "C-c a p") #'my/ng-spec)
 
;;;; Run the dev server / tests from Emacs
(defun my/ng-serve ()
  (interactive)
  (let ((default-directory (or (my/angular-project-p) default-directory)))
    (compile "npx ng serve" t)))
 
(defun my/ng-test ()
  (interactive)
  (let ((default-directory (or (my/angular-project-p) default-directory)))
    (compile "npx ng test --watch=false")))
 
;; (global-set-key (kbd "C-c a r") #'my/ng-serve)
;; (global-set-key (kbd "C-c a T") #'my/ng-test)
 
(provide 'angular)
;;; angular.el ends here
