;;; init-env.el --- Environment variables and PATH setup -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

(defconst my/work-p
  (file-exists-p (expand-file-name "work-machine" user-emacs-directory)))

(provide 'init-env)
;;; init-env.el ends here
