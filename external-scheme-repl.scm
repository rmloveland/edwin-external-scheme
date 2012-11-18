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

;;;; External Scheme subprocess in a buffer

(declare (usual-integrations))

(define-variable external-scheme-repl-prompt-pattern
  "Regexp to match the external Scheme's REPL prompt."
  (os/default-shell-prompt-pattern)
  string?)

(define-variable explicit-external-scheme-file-name
  "If not #f, file name to use for the explicitly requested external Scheme."
  #f
  string-or-false?)

(define-major-mode external-scheme-repl comint "External Scheme REPL"
  "Major mode for interacting with an external Scheme REPL.
Return after the end of the process' output sends the text from the 
    end of process to the end of the current line.

If you accidentally suspend your process, use \\[comint-continue-subjob]
to continue it.

Customisation: Entry to this mode runs the hooks on comint-mode-hook and
external-scheme-repl-mode-hook (in that order)."
  (lambda (buffer)
    (local-set-variable! comint-prompt-regexp
			 (ref-variable external-scheme-repl-prompt-pattern buffer)
			 buffer)
    (local-set-variable! local-abbrev-table
			 (ref-variable external-scheme-repl-mode-abbrev-table buffer)
			 buffer)
    (event-distributor/invoke!
     (ref-variable external-scheme-repl-mode-hook buffer) buffer)))

(define-variable external-scheme-repl-mode-abbrev-table
  "Mode-specific abbrev table for External Scheme REPL mode.")
(define-abbrev-table 'shell-mode-abbrev-table '())

(define-variable external-scheme-repl-mode-hook
  "An event distributor that is invoked when entering External Scheme REPL mode."
  (make-event-distributor))

(define-key 'external-scheme-repl #\tab 'lisp-indent-line)
(define-key 'external-scheme-repl #\) 'lisp-insert-paren)
(define-key 'external-scheme-repl #\c-m-q 'indent-sexp)
(define-key 'external-scheme-repl #\c-a 'comint-bol)


(define-command external-scheme-repl
  "Run an external Scheme REPL, with I/O through buffer *external-scheme-repl*.
With prefix argument, unconditionally create a new buffer and process.
If buffer exists but Scheme process is not running, make new shell.
If buffer exists and Scheme process is running, just switch to buffer
*external-scheme-repl*. 

The location of the Scheme binary to use comes from one of:
(1) the value entered at the prompt
(2) the variable `explicit-external-scheme-file-name', or
(3) the PREFERRED_SCHEME environment variable.

The buffer is put in External Scheme REPL mode, giving commands for sending
input."
  "sRun Scheme: \nP"
  (lambda (scheme-program-name new-buffer?)
    (select-buffer
     (let ((program
	    (or
	     scheme-program-name
	     (ref-variable explicit-external-scheme-file-name)
	     (get-environment-variable "PREFERRED_SCHEME"))))
       (apply make-comint
	      (ref-mode-object external-scheme-repl)
	      (if (not new-buffer?)
		  "*external-scheme-repl*"
		  (new-buffer "*external-scheme-repl*"))
	      program
	      '())))))
