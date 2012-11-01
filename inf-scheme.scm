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

I've plagiarized both Olin Shivers' cmuscheme.el and iuscheme.el by
Chris Haynes and Erik Hilsdale, as well as shell.scm from Edwin itself.

|#

;;;; Scsh subprocess in a buffer

(declare (usual-integrations))

(define-variable inferior-scheme-prompt-pattern
  "Regexp to match prompts in the inferior Scheme Shell."
  (os/default-shell-prompt-pattern)
  string?)

(define-variable explicit-scheme-file-name
  "If not #F, file name to use for explicitly requested inferior shell."
  #f
  string-or-false?)

(define-major-mode inferior-scheme comint "Inferior Scheme"
  "Major mode for interacting with an inferior Scheme.
Return after the end of the process' output sends the text from the 
    end of process to the end of the current line.
Return before end of process output copies rest of line to end (skipping
    the prompt) and sends it.

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
  "Mode-specific abbrev table for Shell mode.")
(define-abbrev-table 'shell-mode-abbrev-table '())

(define-variable inferior-scheme-mode-hook
  "An event distributor that is invoked when entering Shell mode."
  (make-event-distributor))

; (define-key 'inferior-scheme #\tab 'comint-dynamic-complete)
; (define-key 'inferior-scheme #\M-? 'comint-dynamic-list-completions)
(define-key 'inferior-scheme #\return 'comint-send-input)


(define-command run-scheme
  "Run an inferior Scheme, with I/O through buffer *inferior-scheme*.
With prefix argument, unconditionally create a new buffer and process.
If buffer exists but shell process is not running, make new shell.
If buffer exists and shell process is running, just switch to buffer
  *inferior-scheme*.

The location of the scsh binary to use comes from either (1) the
variable `explicit-inferior-scheme-file-name' or (2) the
INFERIOR_SCHEME environment variable.

The buffer is put in inferior-scheme mode, giving commands for sending
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

; '("--" "-lp-default")


; Customize by setting these hooks:
; comint-input-sentinel
; comint-input-filter
; comint-get-old-input

; (define-command scheme-return
;   ""
;   ()
;   (lambda () (scheme-return)))

; (define (scheme-return)
;   (let ((input-start (process-mark (get-buffer-process (current-buffer)))))
;     (if (< (current-point) input-start)
; 	(comint-send-input)
; 	(let ((state (save-excursion
; 		      (parse-partial-sexp input-start (current-point)))))
; 	  (if (and (< (car state) 1)          ; depth in parens is zero
; 		   (not (list-ref state 3))   ; not in a string
; 		   (not (save-excursion       ; nothing after the
; 					      ; point
; 			 (re-search-forward "[^ \t\n\r]" (current-point)
; 					    (end-of-buffer)))))
; 	      (comint-send-input)
; 	      (newline-and-indent))))))
