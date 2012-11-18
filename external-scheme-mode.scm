#| -*-Scheme-*-

Copyright (C) 2012 Rich Loveland <loveland.richard@gmail.com>

This file is NOT part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; External Scheme Mode

(declare (usual-integrations))

(define-command external-scheme-mode
  "A Scheme mode for non-MIT Schemes. Combined with an external Scheme
REPL started with `\#M-x external-scheme-repl', you can evaluate code
from a buffer in this mode using the Scheme of
your choice."
  ()
  (lambda () (set-current-major-mode! (ref-mode-object external-scheme))))

(define-major-mode external-scheme scheme "External Scheme"
  "Major mode specialized for editing non-MIT Scheme code.

This mode inherits from Edwin's built-in Scheme mode, so commands
should be the same, except for the evaluation commands.

The following commands evaluate Scheme expressions in an external
Scheme REPL. You'll need to start it by issuing the command
`#\M-x external-scheme-repl'.

\\[external-scheme-eval-last-sexp] evaluates the expression preceding point.
\\[external-scheme-eval-defun] evaluates the current definition.
\\[external-scheme-eval-region] evaluates the current region.

\\{external-scheme}"
  (lambda (buffer)
    (local-set-variable! syntax-table scheme-mode:syntax-table buffer)
    (local-set-variable! syntax-ignore-comments-backwards #f buffer)
    (local-set-variable! lisp-indent-hook standard-lisp-indent-hook buffer)
    (local-set-variable! lisp-indent-methods scheme-mode:indent-methods buffer)
    (local-set-variable! lisp-indent-regexps scheme-mode:indent-regexps buffer)
    (local-set-variable! comment-column 40 buffer)
    (local-set-variable! comment-locator-hook lisp-comment-locate buffer)
    (local-set-variable! comment-indent-hook lisp-comment-indentation buffer)
    (local-set-variable! comment-start ";" buffer)
    (local-set-variable! comment-end "" buffer)
    (standard-alternate-paragraph-style! buffer)
    (local-set-variable! paragraph-ignore-fill-prefix #t buffer)
    (local-set-variable! indent-line-procedure
			 (ref-command lisp-indent-line)
			 buffer)
    (local-set-variable! mode-line-process
			 '(RUN-LIGHT (": " RUN-LIGHT) "")
			 buffer)
    (local-set-variable! local-abbrev-table
			 (ref-variable external-scheme-mode-abbrev-table buffer)
			 buffer)
    (event-distributor/invoke! (ref-variable external-scheme-mode-hook buffer) buffer)))

(define-variable external-scheme-mode-abbrev-table
  "Mode-specific abbrev table for External Scheme mode.")
(define-abbrev-table 'external-scheme-mode-abbrev-table '())

(define-variable external-scheme-mode-hook
  "An event distributor that is invoked when entering External Scheme mode."
  (make-event-distributor))

; (define-key 'external-scheme #\m-o 'external-scheme-eval-current-buffer)

(define-key 'external-scheme #\M-z 'external-scheme-eval-defun)
(define-key 'external-scheme #\C-M-z 'external-scheme-eval-region)
(define-key 'external-scheme '(#\C-x #\C-e) 'external-scheme-eval-last-sexp)
(define-key 'external-scheme '(#\C-c #\C-z) 'external-scheme-select-repl-other-window)

(define-key 'external-scheme #\M-A 'undefined)
(define-key 'external-scheme #\M-tab 'undefined)
(define-key 'external-scheme '(#\C-c #\C-c) 'undefined)


;;; Procedures.

(define (external-scheme-process)
  "Get the external Scheme REPL's process. Returns #f if no external
REPL is running."
  (let ((filtered-list (filter (lambda (p)
			   (external-scheme-process? p))
			 (process-list))))
    (if (null? filtered-list)
	#f
	(car filtered-list))))

(define (external-scheme-process? process)
  "Is this process the external Scheme REPL's process?"
  (string=? (process-name process)
	    "*external-scheme-repl*"))

(define (external-scheme-running?)
  "Is an external Scheme REPL running?"
  (let ((val (external-scheme-process)))
    (if val #t #f)))

(define (external-scheme-eval-string string)
  "Evaluate a string in the external Scheme's REPL."
  (if (external-scheme-running?)
      (process-send-string (external-scheme-process)
			   (string-append string "\n"))
      (message "No external Scheme REPL is running. Try `#\M-x external-scheme-repl'.")))

(define (external-scheme-eval-region region)
  "Evaluate the region in an external Scheme REPL."
  (let* ((string (region->string region)))
    (external-scheme-eval-string string)))

(define (external-scheme-select-repl-other-window)
  "Open the external Scheme's REPL buffer in the other window.
If no such REPL is running, tell the user to start one."
  (if (external-scheme-running?)
      (select-buffer-other-window
       (find-buffer "*external-scheme-repl*"))
      (message "No external Scheme REPL is running. Try `#\M-x external-scheme-repl'.")))

(define (external-scheme-send-from-mark mark)
  "Send text from the current mark to the external Scheme REPL."
  (external-scheme-eval-region
   (make-region mark (forward-sexp mark 1 'ERROR))))

;;; Commands.

(define-command external-scheme-eval-region
  "Evaluate the region in an external Scheme REPL."
  ()
  (lambda ()
    (external-scheme-eval-region (current-region))))

(define-command external-scheme-eval-defun
  "Evaluate the procedure definition that point is in or before."
  ()
  (lambda ()
    (external-scheme-send-from-mark (current-definition-start))))

(define-command external-scheme-eval-last-sexp
  "Evaluate the expression preceding point."
  ()
  (lambda ()
    (external-scheme-send-from-mark
     (backward-sexp (current-point) 1 'ERROR))))

(define-command external-scheme-select-repl-other-window
  "Open the external Scheme's REPL buffer in the other window.
If no such REPL is running, tell the user to start one."
  ()
  (lambda ()
    (external-scheme-select-repl-other-window)))
