;;; $Header: /repo/cvs.copy/eli/fi-ring.el,v 1.3 1988/03/04 09:10:29 layer Exp $
;;;
;;; This code is very similar to the kill-ring implementation
;;; and implements the fi::subprocess input ring.  Each fi::subprocess buffer
;;; has its own input ring.

(defvar fi:default-input-ring-max 50
  "Default maximum length of input rings.")

(defvar fi::input-ring nil
  "List of previous input to fi::subprocess.")

(defvar fi::input-ring-max fi:default-input-ring-max
  "Maximum length of input ring before oldest elements are thrown away.")

(defvar fi::input-ring-yank-pointer nil
  "The tail of the input ring whose car is the last thing yanked.")

(defvar fi::last-input-search-string ""
  "Last input search string in each fi::subprocess buffer.")

(defvar fi::last-command-was-successful-search nil
  "Switch to indicate that last command was a successful input re-search.")

(defun fi::input-append (string before-p)
  (setq fi::last-command-was-successful-search nil)
  (setcar fi::input-ring
	  (if before-p
	      (concat string (car fi::input-ring))
	      (concat (car fi::input-ring) string))))

(defun fi:input-region (beg end)
  "Delete text between point and mark and save in input ring.
The command fi::yank-input can retrieve it from there.

This is the primitive for programs to kill text into the input ring.
Supply two arguments, character numbers indicating the stretch of text
  to be killed.
If the previous command was also a kill command,
  the text killed this time appends to the text killed last time
  to make one entry in the fi::subprocess input ring."
  (interactive "*r")
  (setq fi::last-command-was-successful-search nil)
  (fi::input-ring-save beg end)
  (delete-region beg end))

(defun fi::input-ring-save (beg end)
  "Save the region on the fi::subprocess input ring but don't kill it."
  (interactive "r")
  (setq fi::last-command-was-successful-search nil)
  (if (eq last-command 'fi:input-region)
      (fi::input-append (buffer-substring beg end) (< end beg))
    (setq fi::input-ring (cons (buffer-substring beg end) fi::input-ring))
    (if (> (length fi::input-ring) fi::input-ring-max)
	(setcdr (nthcdr (1- fi::input-ring-max) fi::input-ring) nil)))
  (setq this-command 'fi:input-region)
  (setq fi::input-ring-yank-pointer fi::input-ring))

(defun fi::rotate-yank-input-pointer (arg)
  "Rotate the yanking point in the fi::subprocess input ring."
  (interactive "p")
  (setq fi::last-command-was-successful-search nil)
  (let ((ring-length (length fi::input-ring))
	(yank-ring-length (length fi::input-ring-yank-pointer)))
    (cond
     ((zerop ring-length)
      (error "Fi::subprocess input ring is empty."))
     ((< arg 0)
      (setq arg (- ring-length (% (- arg) ring-length)))
      (setq fi::input-ring-yank-pointer
	    (nthcdr (% (+ arg (- ring-length yank-ring-length)) ring-length)
		    fi::input-ring)))
     (t
      (setq fi::input-ring-yank-pointer
	    (nthcdr (% (+ arg (- ring-length yank-ring-length)) ring-length)
		    fi::input-ring))))))

(defun fi:pop-input (arg)
  "Yank text from input ring.
Cycle through input ring with each
successive invocation.  Just like fi::yank-input-pop except that it
does not have to be called only after fi::yank-input."
  (interactive "*p")
  (setq fi::last-command-was-successful-search nil)
  (if (not (memq last-command '(fi::yank-input
				fi:re-search-backward-input
				fi:re-search-forward-input)))
      (progn
	(fi::yank-input arg)
	(setq this-command 'fi::yank-input))
      (progn
	(setq this-command 'fi::yank-input)
	(let ((before (< (point) (mark))))
	     (delete-region (point) (mark))
	     (fi::rotate-yank-input-pointer arg)
	     (set-mark (point))
	     (insert (car fi::input-ring-yank-pointer))
	     (if before (exchange-point-and-mark))))))

(defun fi:push-input (arg)
  "Yank text from input ring.
Cycle through input ring in reverse
order with each successive invocation.  Just like fi:pop-input except
that it goes through the ring in the other direction."
  (interactive "*p")
  (setq fi::last-command-was-successful-search nil)
  (if (not (memq last-command '(fi::yank-input
				fi:re-search-backward-input
				fi:re-search-forward-input)))
      (progn
	(fi::yank-input (- (1- arg)))
	(setq this-command 'fi::yank-input))
      (progn
	(setq this-command 'fi::yank-input)
	(let ((before (< (point) (mark))))
	     (delete-region (point) (mark))
	     (fi::rotate-yank-input-pointer (- arg))
	     (set-mark (point))
	     (insert (car fi::input-ring-yank-pointer))
	     (if before (exchange-point-and-mark))))))

(defun fi::yank-input (&optional arg)
  "Reinsert the last fi::subprocess input text.
More precisely, reinsert the input text most recently killed OR yanked.
With just C-U as argument, same but put point in front (and mark at end).
With argument n, reinsert the nth most recent input text.
See also the command fi::yank-input-pop."
  (interactive "*P")
  (setq fi::last-command-was-successful-search nil)
  (fi::rotate-yank-input-pointer (if (listp arg) 0
				 (if (eq arg '-) -1
				     (1- arg))))
  (set-mark (point))
  (insert (car fi::input-ring-yank-pointer))
  (if (consp arg)
      (exchange-point-and-mark)))

(defun fi:list-input-ring (arg &optional reflect)
  "Display contents of input ring, starting at arg.
The list is displayed in reverse order if the optional second
parameter is non-nil."
  (interactive "p")
  (let* ((input-ring-for-list fi::input-ring)
	 (input-ring-max-for-list fi::input-ring-max)
	 (input-ring-yank-pointer-for-list fi::input-ring-yank-pointer)
	 (ring-length (length fi::input-ring))
	 (yank-ring-length (length fi::input-ring-yank-pointer))
	 (loops ring-length)
	 nth
	 first
	 count)
	(if (zerop ring-length) (error "Input ring is empty."))
 	;; We rely on (error) to exit from this function. [HW]
	(if reflect
	  (if (= arg 1)
	    (setq arg -1)
	    (setq arg (1- arg))))
	(cond
	 ((< arg 0)
	  (setq arg (- ring-length (% (- arg) ring-length)))
	  (setq count (1+ arg))
	  (setq nth (% (+ arg (- ring-length yank-ring-length)) ring-length)))
	 ((= arg 0)
	  (setq count 1)
	  (setq nth (% (+ arg (- ring-length yank-ring-length)) ring-length)))
	 (t
	  (setq count arg)
	  (setq arg (1- arg))
	  (setq nth (% (+ arg (- ring-length yank-ring-length)) ring-length))))
	(setq first nth)
	(with-output-to-temp-buffer
	  "*Input Ring*"
	  (save-excursion
	    (set-buffer standard-output)
	    (let ((lastcdr (nthcdr nth input-ring-for-list)))
		 ; GNU Emacs really needs better looping constructs. [HW]
		 (while
		   (not (cond
			 ((= loops 0)
			  t)
			 ((and (= nth (1- ring-length)) (not reflect))
			  (setq nth 0)
			  nil)
			 ((and (= nth 0) reflect)
			  (setq nth (1- ring-length))
			  nil)
			 (t
			  (setq nth (if reflect (1- nth) (1+ nth)))
			  nil)))
		   (insert (int-to-string count) " " (car lastcdr) "\n")
		   (setq lastcdr (nthcdr nth input-ring-for-list))
		   (setq count (if reflect (1- count) (1+ count)))
		   (setq loops (1- loops))
		   (cond
		    ((> count ring-length)
		     (setq count 1))
		    ((< count 1)
		     (setq count ring-length)))))))))

(defun fi::re-search-input-ring (regexp direction)
  "Look for input text that contains string regexp.
Set fi::input-ring-yank-pointer to text."
  (let* ((ring-length (length fi::input-ring))
	 (yank-ring-length (length fi::input-ring-yank-pointer))
	 (nth (- ring-length yank-ring-length))
	 (loops ring-length)
	 (return-value nil)
	 (lastcdr (nthcdr nth fi::input-ring)))
    (if (zerop ring-length) (error "Input ring is empty."))
    ;; We rely on (error) to exit from this function. [HW]
    (while
      (not
       (cond
	((= loops 0)
	 t)
	((string-match regexp (car lastcdr) nil)
	 (setq fi::input-ring-yank-pointer lastcdr)
	 (setq return-value t))
	((and (= nth (1- ring-length)) (>= direction 0))
	 (setq nth 0)
	 nil)
	((and (= nth 0) (< direction 0))
	 (setq nth (1- ring-length))
	 nil)
	(t
	 (setq nth (if (< direction 0) (1- nth) (1+ nth)))
	 nil)))
      (setq lastcdr (nthcdr nth fi::input-ring))
      (setq loops (1- loops)))
    (if return-value (setq fi::last-input-search-string regexp))
    return-value))

(defun fi:re-search-backward-input (arg regexp)
  "Search in input ring for text that contains regexp and yank."
  (interactive "*p\nsRE search input backward: ")
  (if (string= regexp "") (setq regexp fi::last-input-search-string))
  (if fi::last-command-was-successful-search
      (fi::rotate-yank-input-pointer 1))
  (setq fi::last-command-was-successful-search nil)
  (if (let ((found t))
	   (while (and (> arg 0) found)
		  (setq found (fi::re-search-input-ring regexp 1))
		  (setq arg (1- arg))
		  (if (and (> arg 0) found)
		      (fi::rotate-yank-input-pointer 1)))
	   found)
      (progn
	(fi::yank-input-at-pointer)
	(setq this-command 'fi:re-search-backward-input)
	(setq fi::last-command-was-successful-search t))
      (message "Matching string not found in input ring.")))

(defun fi:re-search-forward-input (arg regexp)
  "Search in input ring for text that contains regexp and yank."
  (interactive "*p\nsRE search input forward: ")
  (if fi::last-command-was-successful-search
      (fi::rotate-yank-input-pointer -1))
  (setq fi::last-command-was-successful-search nil)
  (if (string= regexp "") (setq regexp fi::last-input-search-string))
  (if (let ((found t))
	   (while (and (> arg 0) found)
		  (setq found (fi::re-search-input-ring regexp -1))
		  (setq arg (1- arg))
		  (if (and (> arg 0) found)
		      (fi::rotate-yank-input-pointer -1)))
	   found)
      (progn
	(fi::yank-input-at-pointer)
	(setq this-command 'fi:re-search-backward-input)
	(setq fi::last-command-was-successful-search t))
      (message "Matching string not found in input ring.")))

(defun fi::yank-input-at-pointer ()
  "Yank input at current input ring pointer.
Used internally by fi:re-search-backward-input and fi:re-search-forward-input."
  ;; This business of last-command does not work here since the
  ;; `last command' was self-insert-command because of the prompt
  ;; for a regular expression by (fi:re-search-forward-input) and
  ;; (fi:re-search-backward-input).
  (delete-region (process-mark (get-buffer-process (current-buffer))) (point))
  (set-mark (point))
  (insert (car fi::input-ring-yank-pointer)))
