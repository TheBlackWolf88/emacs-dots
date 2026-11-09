;;; init-ai.el --- AI assistant integrations -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;; GPT

(use-package gptel
  :ensure t
  :bind (("C-c g g" . gptel)      ;; open a chat buffer
         ("C-c g s" . gptel-send) ;; send region/prompt
         ("C-c g m" . gptel-menu) ;; transient menu (model, params, etc.)
         ("C-c g r" . gptel-rewrite)) ;; rewrite region in place
  :config
  (require 'url-parse)
  (let* ((u (url-generic-parse-url (getenv "ANTHROPIC_FOUNDRY_BASE_URL")))
         (path (string-remove-suffix "/" (or (url-filename u) ""))))
    (setq gptel-backend
          (gptel-make-anthropic "Foundry"
            :stream t
            :protocol (url-type u)
            :host (url-host u)
            :endpoint (concat path "/v1/messages")
            :key (lambda () (getenv "ANTHROPIC_FOUNDRY_API_KEY"))
            :models '(claude-sonnet-4-6))   ; your deployment name
          gptel-model 'claude-sonnet-4-6)))
(defun my/gptel-ask-buffer (question)
  "Ask QUESTION about the current buffer; show the answer in a q-dismissable buffer."
  (interactive "sAsk about this buffer: ")
  (let ((name (buffer-name))
        (content (buffer-substring-no-properties (point-min) (point-max))))
    (gptel-request
        (format "Buffer `%s`:\n\n%s\n\nQuestion: %s" name content question)
      :system "Answer concisely, based on the buffer contents."
      :callback
      (lambda (response info)
        (if (stringp response)
            (let ((buf (get-buffer-create "*gptel-answer*")))
              (with-current-buffer buf
                (let ((inhibit-read-only t))
                  (erase-buffer)
                  (insert response)
                  (goto-char (point-min)))
                (special-mode)
                (visual-line-mode 1))
              (pop-to-buffer buf))
          (message "gptel: request failed: %s" (plist-get info :status)))))))
(global-set-key (kbd "C-c g q") #'my/gptel-ask-buffer)
  
(use-package agent-shell
  :ensure t
  :config
  (setq agent-shell-preferred-agent-config
        (agent-shell-anthropic-make-claude-code-config)))

(provide 'init-ai)
;;; init-ai.el ends here


