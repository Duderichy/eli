;; local-fi-developer-hooks.el

;; This file is not for public distribution.
;; It contains extra hooks for fi developers only, things like special
;; file write hooks that automatically time stamp runtime system files.
;; If this file is present, it is loaded by fi-site-init.

;;;; NOT USED ANYMORE:
(defun fi::update-acl-id ()
  (interactive "")
  (save-excursion
    (goto-char (point-min))
    (let ((type
	   (cond ((re-search-forward "^void ACLID_" 1500 t) 'c)
		 ((re-search-forward "^(def-runtime-q ACLID_" 1500 t) 'rs))))
      (when type
	(condition-case ()
	    (progn
	      (delete-region (progn (goto-char (match-end 0)) (point))
			     (progn (end-of-line) (point)))
	      (let ((str
		     (concat (substring buffer-file-name
					(+ 1
					   (or (position ?/
							 buffer-file-name
							 :from-end t)
					       -1)))
			     "_"
			     (let ((s (current-time-string)))
			       (concat (substring s 22 24)
				       (substring s 4 7)
				       (substring s 8 16)))
			     "_"
			     (user-login-name))))
		(setq str (substitute ?_ ?. str))
		(setq str (substitute ?_ ?/ str))
		(setq str (substitute ?_ ?: str))
		(setq str (substitute ?_ ?- str))
		(setq str (substitute ?_ ?  str))
		(insert str)
		(insert (case type
			  (c "(){}")
			  (rs " ())")))))
	  (foo (message "error updating modify line...")
	       (sit-for 1))))))
  nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; setup C code edit mode

(condition-case ()
    (progn
      (require 'cc-mode)
      (require 'cc-styles)
      (add-hook 'c-mode-common-hook
		(function (lambda () (c-set-style "bsd")))))
  (error nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;(add-hook 'fi:common-lisp-mode-hook
;;;	  (function
;;;	   (lambda ()
;;;	     (pushnew 'fi::update-acl-id local-write-file-hooks))))
;;;
;;;(add-hook 'c-mode-hook
;;;	  (function
;;;	   (lambda ()
;;;	     (pushnew 'fi::update-acl-id local-write-file-hooks))))
;;;
;;;(add-hook 'c++-mode-hook
;;;	  (function
;;;	   (lambda ()
;;;	     (pushnew 'fi::update-acl-id local-write-file-hooks))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun update-modify-line ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (if (search-forward "-[" 500 t)
	(let ((debug-on-error nil))
	  (condition-case ()
	      (let ((from (point)))
		(search-forward "]-" (+ (point) 100))
		(backward-char 2)
		(delete-region from (point))
		(insert (current-time-string)
			" by "
			(user-login-name)))
	    (error (message "error updating modify line...")
		   (sit-for 1))))))
  nil)

(put 'excl::.primcall 'fi:lisp-indent-hook 1)
