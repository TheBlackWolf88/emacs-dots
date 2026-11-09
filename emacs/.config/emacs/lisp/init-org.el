;;; init-org.el --- Org mode configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;;; Org-Mode
;;; Org mode — todos & meetings
(use-package org
  :ensure nil ; built-in
  :hook (org-mode . org-indent-mode)
  :custom
  (org-directory "~/dev/org")
  (org-agenda-files (list (expand-file-name "todo.org" org-directory)
                           (expand-file-name "meetings.org" org-directory)))
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)" "|" "DONE(d!)" "CANCELLED(c@)")))
  (org-log-done 'time)
  (org-log-into-drawer t)
  (org-agenda-start-with-log-mode nil)
  (org-agenda-window-setup 'current-window)
  (org-agenda-restore-windows-after-quit t)
  (org-deadline-warning-days 5)
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture)))

(use-package org
  :ensure nil
  :custom
  (org-agenda-custom-commands
   '(("d" "Today: todos + meetings"
      ((agenda "" ((org-agenda-span 'day)
                    (org-agenda-overriding-header "Today")))
       (tags-todo "meeting" ((org-agenda-overriding-header "Meetings")))
       (todo "NEXT" ((org-agenda-overriding-header "Next actions")))
       (todo "TODO" ((org-agenda-overriding-header "Open todos")))))))
  :bind (("C-c d" . (lambda () (interactive) (org-agenda nil "d")))))

(use-package org
  :ensure nil
  :custom
  (org-capture-templates
   '(("t" "Todo" entry (file+headline "~/dev/org/todo.org" "Inbox")
      "* TODO %?\n%U\n%a\n" :empty-lines 1)

     ("m" "Meeting" entry (file+headline "~/dev/org/meetings.org" "Meetings")
      "* MEETING %? :meeting:\n%^T\n:PROPERTIES:\n:LOCATION:\n:ATTENDEES:\n:END:\n"
      :empty-lines 1))))

(provide 'init-org)
;;; init-org.el ends here
