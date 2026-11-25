;;; init-latex.el --- LaTeX writing (AUCTeX, RefTeX, citar, pdf-tools) -*- lexical-binding: t; -*-
;;; Commentary:
;; Built around ~/dev/thesis: latexmk + biblatex/biber, chapters pulled
;; in with \input, prose in Hungarian with English notes.
;;
;;   C-c C-c      compile with latexmk; press again to view the PDF
;;   C-c C-v      show the current source line in the PDF (SyncTeX)
;;   C-mouse-1    in the PDF: jump back to the source
;;   C-c `        jump to the next compile error
;;   C-c =        table of contents (RefTeX)
;;   C-c ( / C-c )  insert \label / \ref
;;   C-c [        insert a citation (citar)
;;   C-c C-e      insert environment     C-c C-s  insert section
;;                (C-c C-s shadows the global consult map in LaTeX buffers)
;;   C-c C-o C-b  fold markup in the buffer, C-c C-o b to unfold
;;   M-$          correct the misspelling at point (jinx)
;;; Code:

;;;; PATH

;; Arch installs biber to /usr/bin/vendor_perl, which only gets onto
;; PATH through /etc/profile.d (bash login shells). fish -- and so
;; exec-path-from-shell -- doesn't have it, and latexmk run from Emacs
;; then fails at the bibliography step.
(let ((dir "/usr/bin/vendor_perl"))
  (when (and (not (executable-find "biber"))
             (file-executable-p (expand-file-name "biber" dir)))
    (add-to-list 'exec-path dir t)
    (setenv "PATH" (concat (getenv "PATH") path-separator dir))))

;;;; AUCTeX

(defun my/latex-use-latexmk ()
  "Make latexmk the default for \\[TeX-command-master]."
  (setq TeX-command-default "LatexMk"))

(defun my/latex-master-from-latexmkrc ()
  "Point `TeX-master' at the main file named in the nearest .latexmkrc.
This lets chapters/*.tex (and chapters/fejlesztoi/*.tex) compile
thesis.tex without per-file local variables.  An explicit file- or
dir-local `TeX-master' still takes precedence."
  (when (and (derived-mode-p 'LaTeX-mode)
             buffer-file-name
             (not (local-variable-p 'TeX-master)))
    (when-let* ((root (locate-dominating-file buffer-file-name ".latexmkrc"))
                (main (with-temp-buffer
                        (insert-file-contents (expand-file-name ".latexmkrc" root))
                        (when (re-search-forward
                               "@default_files\\s-*=\\s-*(\\s-*['\"]\\([^'\"]+\\)['\"]"
                               nil t)
                          (expand-file-name (match-string 1) root)))))
      (setq-local TeX-master
                  (if (file-equal-p main buffer-file-name)
                      t
                    (file-name-sans-extension main))))))

;; AUCTeX's main feature is `tex', not `auctex'.
(use-package tex
  :ensure auctex
  :init
  (add-hook 'LaTeX-mode-hook #'my/latex-use-latexmk)
  (add-hook 'LaTeX-mode-hook #'turn-on-reftex)
  (add-hook 'LaTeX-mode-hook #'TeX-fold-mode)
  (add-hook 'LaTeX-mode-hook #'TeX-source-correlate-mode)
  (add-hook 'LaTeX-mode-hook #'visual-line-mode) ; paragraphs are one long line
  (add-hook 'hack-local-variables-hook #'my/latex-master-from-latexmkrc)
  :custom
  (TeX-parse-self t)
  (TeX-save-query nil)              ; save all buffers before compiling, don't ask
  (TeX-source-correlate-method 'synctex)
  (TeX-source-correlate-start-server t)
  (TeX-view-program-selection '((output-pdf "PDF Tools")))
  (reftex-plug-into-AUCTeX t)
  :config
  ;; %t is the master file, so this works from any chapter buffer.
  ;; The project's .latexmkrc handles pdflatex/biber passes.
  (add-to-list 'TeX-command-list
               '("LatexMk"
                 "latexmk -pdf -synctex=1 -interaction=nonstopmode -file-line-error %t"
                 TeX-run-TeX nil (LaTeX-mode)
                 :help "Build with latexmk (runs biber as needed)"))
  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer))

;;;; PDF viewing

(use-package pdf-tools
  ;; Defers loading -- and the one-time build of its epdfinfo server --
  ;; until the first PDF is opened.
  :init (pdf-loader-install t)
  :custom (pdf-view-display-size 'fit-width))

;;;; Faster input

(use-package cdlatex
  ;; In math: `a -> \alpha, `8 -> \infty, fr<TAB> -> \frac{}{}, TAB
  ;; moves to the next field.  Outside math: equ<TAB>, fig<TAB>, ...
  :hook (LaTeX-mode . turn-on-cdlatex))

;;;; Citations

(use-package citar
  ;; No `citar-bibliography' set: in LaTeX buffers citar reads the
  ;; \addbibresource files of the master document.
  :init
  (with-eval-after-load 'reftex
    (keymap-set reftex-mode-map "C-c [" #'citar-insert-citation)))

;;;; Spelling

(use-package jinx
  ;; Needs enchant plus hunspell dictionaries:
  ;;   pacman -S hunspell hunspell-hu hunspell-en_us
  :hook (LaTeX-mode . jinx-mode)
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages))
  :custom (jinx-languages "hu_HU en_US"))

;;;; LSP (texlab, installed through mason in init-dev)

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((LaTeX-mode plain-TeX-mode) . ("texlab"))))
(add-hook 'LaTeX-mode-hook #'eglot-ensure)

(defun my/latex-unshadow-auctex-keys ()
  "Keep eglot's key prefixes from hiding AUCTeX commands.
init-dev binds keys like C-c C-c a in `eglot-mode-map'.  Minor-mode
maps take precedence, so in LaTeX buffers C-c C-c (compile) would
wait for the `a'.  Give eglot a copy of its map in this buffer with
the prefixes that conflict with a `LaTeX-mode-map' command removed."
  (when (and (bound-and-true-p eglot--managed-mode)
             (derived-mode-p 'LaTeX-mode)
             (not (assq 'eglot--managed-mode minor-mode-overriding-map-alist)))
    (let* ((map (copy-keymap eglot-mode-map))
           (c-c (lookup-key map (kbd "C-c")))
           clashes)
      (when (keymapp c-c)
        (map-keymap
         (lambda (event def)
           (let* ((key (vector ?\C-c event))
                  (mode-def (lookup-key (current-local-map) key)))
             (when (and (keymapp def)
                        mode-def (not (numberp mode-def)) (not (keymapp mode-def)))
               (push key clashes))))
         c-c))
      (when clashes
        (dolist (key clashes)
          (define-key map key nil t))
        (push (cons 'eglot--managed-mode map) minor-mode-overriding-map-alist)))))
(add-hook 'eglot-managed-mode-hook #'my/latex-unshadow-auctex-keys)

(provide 'init-latex)
;;; init-latex.el ends here
