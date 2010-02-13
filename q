#!/usr/bin/env gsi-script
;; -*- scheme -*-

(define args (cdr (command-line)))

(define servicename #f)

(if (pair? args)
    (begin
      (set! servicename (car args))
      (set! args (cdr args)))
    (begin
      (set! servicename "default")))

(include "scmlib/qemu.scm")

(eval
 `(include ,(string-append (~/ ".cj-qemucontrol/") servicename ".scm")))

(qemu)
