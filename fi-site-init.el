;; $Header: /repo/cvs.copy/eli/fi-site-init.el,v 1.75 1996/06/28 00:03:28 layer Exp $
;;
;; The Franz Inc. Lisp/Emacs interface.

(setq fi:emacs-lisp-interface-version "2.0.19")
(defvar fi::required-ipc-version 1)
(defvar fi::load-subprocess-files t)
(defvar fi::install-acl-menubar t)
(defvar fi::build-time nil)
(defvar fi::emacs-type nil)

(load "fi-version.el")

(require 'cl)

;; It would be nice to be able to differentiate between NT and 95, but that
;; doesn't appear possible right now.  The follow variable should default
;; to nil on Windows 95, when that is possible.
;;(when (on-ms-windows) (setq fi::load-subprocess-files nil))

(when (and (or (eq fi::emacs-type 'emacs19) (eq fi::emacs-type 'xemacs19))
	   (not (on-ms-windows)))
  ;; needed for setf expanations (on some version 19.xx) when they are
  ;; compiled with non-version 19 byte-compilers.
  (let ((debug-on-error nil))
    (condition-case nil
	(require 'cl-compat)
      (error nil))))

(defvar fi::initialization-forms nil)
(defun fi::initialize-emacs-lisp-interface ()
  (when fi::initialization-forms
    (dolist (form (nreverse fi::initialization-forms))
      (eval form))
    (setq fi::initialization-forms nil)))

(unless (fboundp 'add-hook)	;not in 18.59
  (defun add-hook (hook function &optional append)
    "Add to the value of HOOK the function FUNCTION.
FUNCTION is not added if already present.
FUNCTION is added (if necessary) at the beginning of the hook list
unless the optional argument APPEND is non-nil, in which case
FUNCTION is added at the end.

HOOK should be a symbol, and FUNCTION may be any valid function.  If
HOOK is void, it is first set to nil.  If HOOK's value is a single
function, it is changed to a list of functions."
    (or (boundp hook) (set hook nil))
    ;; If the hook value is a single function, turn it into a list.
    (let ((old (symbol-value hook)))
      (if (or (not (listp old)) (eq (car old) 'lambda))
	  (set hook (list old))))
    (or (if (consp function)
	    (member function (symbol-value hook))
	  (memq function (symbol-value hook)))
	(set hook
	     (if append
		 (nconc (symbol-value hook) (list function))
	       (cons function (symbol-value hook)))))))

;; This style of loading is more appropriate on a single-user machine, like
;; a Windows machine.  It is even more appropriate on Windows where `make'
;; does not exist except for people who pay for it.  It seems to be the
;; best way to deal with the issue of how to compile the .el files.
(defvar fi:compile-at-load-time (on-ms-windows)
  "*If non-nil, then compile and load files in the fi/ directory.
Otherwise, the .elc will be loaded in preference to the .el file, if it
exists.")

(defvar fi::load-el-files-only nil)

(defun fi::load (file &rest load-before-compile)
  (cond
   (fi::load-el-files-only
    (let ((lib-file (locate-library file))
	  el-lib-file)
      (unless lib-file (error "can't find file %s" file))
      (dolist (required-file load-before-compile)
	(load required-file))
      (cond ((string-match "\\.el$" lib-file)
	     (load lib-file))
	    ((string-match "\\.elc$" lib-file)
	     (load (substring lib-file 0 (- (length lib-file) 1))))
	    (t (error "not el or elc")))))
   (fi:compile-at-load-time
    (let ((lib-file (locate-library file))
	  el-lib-file)
      (unless lib-file (error "can't find file %s" file))
      (dolist (required-file load-before-compile)
	(load required-file))
      (cond ((string-match "\\.el$" lib-file)
	     ;; this compiles and loads:
	     (byte-compile-file lib-file t))
	    ((and (string-match "\\.elc$" lib-file)
		  (file-newer-than-file-p
		   (setq el-lib-file
		     (substring lib-file 0 (- (length lib-file) 1)))
		   lib-file))
	     (byte-compile-file el-lib-file t))
	    (t (load lib-file)))))
   (t (load file))))

(defun fi::load-compiled (file &rest load-before-compile)
  (let ((lib-file (locate-library file)))
    (unless lib-file (error "can't find file %s" file))
    (dolist (required-file load-before-compile)
      (load required-file))
    (cond ((string-match "\\.el$" lib-file)
	   ;; no .elc file
	   (byte-compile-file lib-file t)
	   (setq lib-file (format "%sc" lib-file)))
	  (t
	   (let* ((xx (string-match "\\(.*\\)\\.elc$" lib-file))
		  (base (substring lib-file (match-beginning 1)
				   (match-end 1)))
		  (el (format "%s.el" base))
		  (elc (format "%s.elc" base)))
	     (when (file-newer-than-file-p el elc)
	       (byte-compile-file el t)))))
    (load lib-file)))

(fi::load "fi-keys")			; load before fi-modes
(fi::load "fi-modes")
(when fi:lisp-do-indentation
  (fi::load "fi-indent"))
(fi::load "fi-utils")
(fi::load "fi-gnu")

(unless fi::load-subprocess-files
  (defvar fi:package nil)
  (make-variable-buffer-local 'fi:package)
  ;; used in Common Lisp edit mode:
  (setq fi::common-lisp-backdoor-main-process-name nil))

(when fi::load-subprocess-files
  (fi::load "fi-subproc")
  (fi::load "fi-sublisp")
  (fi::load "fi-basic-lep")
  (fi::load "fi-lep")
  (fi::load "fi-dmode")
  (fi::load "fi-composer")
  (fi::load "fi-lze")
  (fi::load "fi-changes")
  (fi::load "fi-db")
  (fi::load "fi-stream")

  (when (eq fi::emacs-type 'epoch)
    (fi::load "fi-leep0")
    (fi::load "fi-leep"))

  (when (eq fi::emacs-type 'xemacs19)
    (fi::load "fi-leep0")
    (fi::load "fi-leep-xemacs"))

  (fi::load "fi-ring")
  (fi::load "fi-filec")

  ;; `shell' and `rlogin' modes:
  (fi::load "fi-shell")
  (fi::load "fi-rlogin")
  (fi::load "fi-telnet")
  (fi::load "fi-su"))

(autoload 'fi:clman         "fi-clman" nil t)
(autoload 'fi:clman-mode    "fi-clman" nil t)
(autoload 'fi:clman-apropos "fi-clman" nil t)

(condition-case nil
    (fi::load "local-fi-developer-hooks")
  (error nil))

(setq fi:package-loaded t)

;; the test for GNU Emacs 19 has to be after that for xemacs, because
;; the version of xemacs is 19.* too!

(when fi::load-subprocess-files
  (cond ((eq fi::emacs-type 'xemacs19)
       (fi::load "fi-xemacs"))
      ((eq fi::emacs-type 'emacs19)
       (fi::load "fi-emacs19"))
      (t (fi::load "fi-emacs18"))))

(defun fi::top-level ()
  (fi::initialize-emacs-lisp-interface)
  (eval fi::build-time))

(if fi::build-time
    (progn
      (setq fi::build-time top-level)
      (setq top-level '(fi::top-level)))
  (fi::initialize-emacs-lisp-interface))

(provide 'fi-site-init)
