#| -*-Scheme-*-

Copyright (C) 2012 Rich Loveland

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

I've plagiarized both Olin Shivers' `cmuscheme.el' and `iuscheme.el' by
Chris Haynes and Erik Hilsdale, as well as `shell.scm' from Edwin itself.

|#

;;;; Scsh subprocess in a buffer

(declare (usual-integrations))

(define-variable inferior-scheme-prompt-pattern
  "Regexp to match prompts in the inferior Scheme."
  (os/default-shell-prompt-pattern)
  string?)

(define-variable explicit-inferior-scheme-file-name
  "If not #f, file name to use for explicitly requested inferior Scheme."
  #f
  string-or-false?)

(define-major-mode inferior-scheme comint "Inferior Scheme"
  "Major mode for interacting with an inferior Scheme.
Return after the end of the process' output sends the text from the 
    end of process to the end of the current line.

If you accidentally suspend your process, use \\[comint-continue-subjob]
to continue it.

Customisation: Entry to this mode runs the hooks on comint-mode-hook and
inferior-scheme-mode-hook (in that order)."
  (lambda (buffer)
    (local-set-variable! comint-prompt-regexp
			 (ref-variable inferior-scheme-prompt-pattern buffer)
			 buffer)
    (local-set-variable! local-abbrev-table
			 (ref-variable inferior-scheme-mode-abbrev-table buffer)
			 buffer)
    (event-distributor/invoke!
     (ref-variable inferior-scheme-mode-hook buffer) buffer)))

(define-variable inferior-scheme-mode-abbrev-table
  "Mode-specific abbrev table for Inferior Scheme mode.")
(define-abbrev-table 'shell-mode-abbrev-table '())

(define-variable inferior-scheme-mode-hook
  "An event distributor that is invoked when entering Inferior Scheme mode."
  (make-event-distributor))

(define-key 'inferior-scheme #\tab 'lisp-indent-line)
(define-key 'inferior-scheme #\) 'lisp-insert-paren)
(define-key 'inferior-scheme #\c-m-q 'indent-sexp)


(define-command run-scheme
  "Run an inferior Scheme, with I/O through buffer *inferior-scheme*.
With prefix argument, unconditionally create a new buffer and process.
If buffer exists but Scheme process is not running, make new shell.
If buffer exists and Scheme process is running, just switch to buffer
  *inferior-scheme*. 

The location of the Scheme binary to use comes from either (1) the
variable `explicit-inferior-scheme-file-name' or (2) the
INFERIOR_SCHEME environment variable.

The buffer is put in Inferior Scheme mode, giving commands for sending
input."
  "sRun Scheme: \nP"
  (lambda (scheme-program-name new-buffer?)
    (select-buffer
     (let ((program
	    (or
	     scheme-program-name
	     (ref-variable explicit-inferior-scheme-file-name)
	     (get-environment-variable "INFERIOR_SCHEME"))))
       (apply make-comint
	      (ref-mode-object inferior-scheme)
	      (if (not new-buffer?)
		  "*inferior-scheme*"
		  (new-buffer "*inferior-scheme*"))
	      program
	      '())))))
