;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;;hey guys guy here

;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)

(require 'init-package)
(require 'init-env)        ; must come before anything reading env vars
(require 'init-ui)
(require 'init-editing)
(require 'init-completion)
(require 'init-dev)
(require 'init-org)
(require 'angular)
(when my/work-p
  (require 'init-ai)
  (require 'init-work))

;;; init.el ends here

