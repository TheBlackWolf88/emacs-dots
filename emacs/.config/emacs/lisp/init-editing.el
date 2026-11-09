;;; init-editing.el --- Editing behavior and buffer management -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(global-set-key (kbd "C-p") (lambda () (interactive) (forward-line -5)))
(global-set-key (kbd "C-n") (lambda () (interactive) (forward-line 5)))
(global-set-key (kbd "C-S-p") (lambda () (interactive) (forward-line -1)))
(global-set-key (kbd "C-S-n") (lambda () (interactive) (forward-line 1)))

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

(setq auto-save-file-name-transforms
  `((".*" ,(concat user-emacs-directory "auto-save/") t)))
(setq backup-directory-alist
  `((".*" . ,(concat user-emacs-directory "backups/"))))

(defun custom-kill-buffer-fn (&optional arg)
"When called with a prefix argument -- i.e., C-u -- kill all interesting
buffers -- i.e., all buffers without a leading space in the buffer-name.
When called without a prefix argument, kill just the current buffer
-- i.e., interesting or uninteresting."
(interactive "P")
  (cond
    ((and (consp arg) (equal arg '(4)))
      (mapc
        (lambda (x)
          (let ((name (buffer-name x)))
            (unless (eq ?\s (aref name 0))
              (kill-buffer x))))
        (buffer-list)))
    (t
     (kill-buffer (current-buffer)))))

(global-set-key [f5] 'custom-kill-buffer-fn)

(setq create-lockfiles nil)

(provide 'init-editing)
;;; init-editing.el ends here

