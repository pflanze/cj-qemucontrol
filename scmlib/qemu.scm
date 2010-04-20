;;hmm lib for settings
(define ~/
  (string-append (getenv "HOME") "/"))

;; ---- lib

(define (bash-command str . args)
  (let ((p (open-process (list path: "bash"
			       arguments: (cons "-c" (cons str args))
			       stdin-redirection: #f
			       stdout-redirection: #f
			       stderr-redirection: #f))))
    ;;HMM yeah and we would have wanted to pass back the exit status (again)
    ;;hmheh what is p btw?h
    (process-status p)))

(define (xbash-command . args)
  (let ((res (apply bash-command args)))
    (if (zero? res)
	(void)
	(error "bash exited with:" ;; str
	       res))))

(define (singlequote-sh str)
  (list->string
   (cons #\'
	 (let rec ((lis (string->list str)))
	   (if (null? lis)
	       '(#\')
	       (let ((ch (car lis)))
		 (if (char=? ch #\')
		     (cons #\'
			   (cons #\\
				 (cons #\'
				       (cons #\'
					     (rec (cdr lis))))))
		     (cons ch
			   (rec (cdr lis))))))))))

(define (map-accepting-shorter-lis2 fn lis1 lis2)
  (let lp ((lis1 lis1)
	   (lis2 lis2))
    (if (null? lis2)
	'()
	(if (null? lis1)
	    (error "lis2 too long")
	    (cons (fn (car lis1)
		      (car lis2))
		  (lp (cdr lis1)
		      (cdr lis2)))))))


(define q singlequote-sh)

(define a string-append)

(define (lines . args)
  (apply a
	 (map (lambda (str)
		(a str "\n"))
	      args)))

(define (j . args)
  ;; do *not* quote the individual args as j is being used in cases
  ;; where the shell must see the contents, like parens, or "$@"
  (apply a
	 (map (lambda (str)
		(a str " "))
	      args)))

(define (xbash . args)
  (apply lines "set -eu" args))

;; to the toplevel so as to make it overridable by user config:
(define driveoptions
  (list "-hda"
	"-hdd"
	"-hdb"
	;; man qemu: "you cannot use -hdc and -cdrom at the same time"!:
	;; so, not sure, grr, how to make this into the code here
	;; hmm. well maybe qemu will complain by itself.
	"-hdc"))


(define (integer x)
  (inexact->exact (round x)))

(define (virtual-memory-limit)
  ;; give some more memory than what qemu will offer in the vm, for
  ;; both some (hypothetic) overhead (pagetables?well.whatever) and on
  ;; top of that some constant (for the qemu 'binary'/processing
  ;; memory)

  ;; (Actually the limit to just start a 1024MB instance in one case
  ;; instance was factor 1.15 and add 0)
  (define (MiB->KiB x)
    (* x 1024))
  (integer
   (+ (* (MiB->KiB ram-MB) 1.2)
      (MiB->KiB 200))))

(define (b:limits)
  (a "ulimit -S -v " (->string (virtual-memory-limit))))

(define (b:set var val)
  (a var "="
     (q val)))

(define (->string v)
  (cond ((string? v)
	 v)
	((number? v)
	 (number->string v))
	(else
	 (error "not a string nor number:" v))))

(define (maybe-file-info path #!optional (chase? #t))
  (with-exception-catcher
   (lambda (e)
     (if (no-such-file-or-directory-exception? e)
	 #f
	 (raise e)))
   (lambda ()
     (file-info path chase?))))

(define (make--* type)
  (lambda (path)
    (cond ((maybe-file-info path #f)
	   => (lambda (info)
		(eq? (file-info-type info) type)))
	  (else
	   #f))))
  
(define -f (make--* 'regular))
(define -d (make--* 'directory))

(define additional-options '())
(define (add-options! . args)
  ;; (could add then reverse in the end instead)
  (set! additional-options (append additional-options args)))

(define redirections #f)
(define use-tablet? #f)
(define win2k-hack? #f)
(define soundhw #f)
(define net:nic-model "e1000")

(define qemupath "qemu-system-x86_64")

(define uncompresscmd
  (let ((res (bash-command "which pigz >/dev/null 2>&1")))
    (case res
      ((0) "pigz")
      ((256) "gzip")
      (else (error "error running which, exit/signal status:" res)))))

(define (script)
  (define monitorpath (a "unix:"monitorfile",server,nowait"))
  (let ((qemucmdline
	 (apply j
		`(,qemupath
		  "-no-quit"
		  "-monitor" ,(q monitorpath)
		  "-alt-grab"
		  ,(if win2k-hack? "-win2k-hack" "")
		  ,@(map-accepting-shorter-lis2
		     (lambda (driveoption path)
		       (j driveoption (q path)))
		     driveoptions
		     (cond ((list? diskpaths)
			    diskpaths)
			   ((string? diskpaths)
			    (list diskpaths))
			   (else (error "diskpaths must be a list of strings or a string"))))
		  "-m" ,(q (->string ram-MB))
		  ,(if smp (j "-smp" (->string smp)) "")
		  ,(if soundhw (j "-soundhw" soundhw "hda") "")	;; still dunno what the hda is for.
		  ,(if use-tablet? "-usbdevice tablet" "")
		  ,(if net:nic-model
		       (j "-net" (a "nic,model=" net:nic-model)
			  ;; and the other part of the net pair:
			  "-net" "user")
		       "")
		  ,(or redirections "")
		  ,@additional-options))))
    (xbash
     (b:limits)
     (if (-f statefile)
	 (lines "("
		(j uncompresscmd "-c -d" (q statefile))
		(j "mv" (q statefile) (q (a statefile ".old")))
		(j ") |" qemucmdline "-incoming" (q "exec: cat") "\"$@\""))
	 (j "exec" qemucmdline "\"$@\"")))))

(define statefile #f)
(define monitorfile #f)

(define dry-run? #f)

(define (qemu)
  (define servicefolder (a ~/ "tmp/cj-qemucontrol/" servicename))
  (if (not (-d servicefolder))
      (create-directory servicefolder))
  (set! monitorfile (a servicefolder "/monitor"))
  (set! statefile (a servicefolder "/STATEFILE.gz"))

  (if dry-run? 
      (println (script))
      (apply xbash-command (script) args)))

