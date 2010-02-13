;;hmm lib for settings
(define ~/
  (string-append (getenv "HOME") "/"))

;; ---- lib

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
(define virtual-memory-limit 1200000)
(define driveoptions
  (list "-hda"
	"-hdd"
	"-hdb"
	;; man qemu: "you cannot use -hdc and -cdrom at the same time"!:
	;; so, not sure, grr, how to make this into the code here
	;; hmm. well maybe qemu will complain by itself.
	"-hdc"))

(define (b:limits)
  (a "ulimit -S -v " (->string virtual-memory-limit)))

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
(define qemupath "qemu-system-x86_64")

(define (script)
  (define monitorpath (a "unix:"monitorfile",server,nowait"))
  (define tablet (if use-tablet? "-usbdevice tablet" ""))
  (let ((qemucmdline
	 (apply j
		`(,qemupath
		  "-no-quit"
		  "-monitor" ,(q monitorpath)
		  "-alt-grab"
		  ,(if win2k-hack? "-win2k-hack" "")
		  ,@(if (list? diskpaths)
			(map-accepting-shorter-lis2
			 (lambda (driveoption path)
			   (j driveoption (q path)))
			 driveoptions
			 diskpaths)
			;; and the backward-compatible way (common-lispy right..)
			(list (j (car driveoptions) (q diskpaths))))
		  "-m" ,(q (->string ram-MB))
		  ,(if smp (j "-smp" (->string smp)) "")
		  ,(if soundhw (j "-soundhw" soundhw "hda") "") ;; still dunno what the hda is for.
		  ,tablet
		  ,(or redirections "")
		  ,@additional-options))))
    (xbash
     (b:limits)
     (if (-f statefile)
	 (lines "("
		(j "gzip -c -d" (q statefile))
		(j "mv" (q statefile) (q (a statefile ".old")))
		(j ") |" qemucmdline "-incoming" (q "exec: cat") "\"$@\""))
	 (j "exec" qemucmdline "\"$@\"")))))

(define (bash-command str . args)
  (let ((p (open-process (list path: "bash"
			       arguments: (cons "-c" (cons str args))
			       stdin-redirection: #f
			       stdout-redirection: #f
			       stderr-redirection: #f))))
    ;;HMM yeah and we would have wanted to pass back the exit status (again)
    ;;hmheh what is p btw?h
    (let ((res (process-status p)))
      (if (zero? res)
	  (void)
	  (error "bash exited with:" ;; str
		 res)))))

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
      (apply bash-command (script) args)))

