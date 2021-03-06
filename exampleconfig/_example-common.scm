;; ---- settings

;; This is Scheme code;

;; Booleans are #f for false and #t for true. Actually all non-#f
;; values are interpreted as true: so there are two situations where
;; #f is used, for one in places where only false and true is
;; distinguished (Boolean data type), and in which case you'd say #t
;; to say true, and in places where optionally there can be given some
;; value and the actual non-false value is being relevant (Maybe data
;; type in some other languages). By convention, variables that only
;; take booleans are ending with a question mark.

;; You can create definitions on your own, too (better start your own
;; variables with an underscore to avoid potential conflicts), and use
;; them in later definitions, for example
;;  (define _basedir "/my/base/directory/")
;;  (define disks (disks_ hda: (string-append _basedir "hda.img")))
;;  instead of string-append you can also just use the letter a:
;;  (define disks (disks_ hda: (a _basedir "hda.img")))
;; You can refer to your home directory path by using the ~/ variable:
;;  (define disks (disks_ hda: (a ~/ "images/hda"))) ;; where images is a subdir of your home

;; By including this file into others (see the example.scm and
;; example-smp.scm files as examples) you can adapt the settings
;; selectively to different usages.

;; If you want to see what is going to be executed in bash syntax,
;; then uncomment the following line:
;; (define dry-run? #t)

;; required settings:
(define disks (disks_ hda: "/dev/plain/windows2000"))
;; or (define disks (disks_ hda: "somepath" hdc: "someotherpath" cdrom: "/dev/cdrom")),
;; it also supports hdb: and hdd: (although there's a conflict of with cdrom:)

(define ram-MB 384)

(define net:type 
  ;; 'user or 'tap
  'user)
;;(define net:tap-device "tap0");; only necessary with net:type set to 'tap

;; optional settings (can be removed or set to #f):
(define redirections "-redir tcp:3022::22")
(define use-tablet? #t)
(define win2k-hack? #t)
(define soundhw #f)

;; (define net:nic-model "e1000");; if explicitely set to #f, no -net option will be issued

;; optional settings (they have default values, but can't be set to #f):
;;(define virtual-memory-limit 1200000)
;;(define qemupath "qemu-system-x86_64")

;; If you need to add random other options, you can use:
;; (add-options! "-someoptionwithvalue" "optionvalue")
;; or just
;; (add-options! "-someoptionwithoutvalue")

;; The base folder to put the command socket and state files (a
;; subfolder named after the service will be created automatically):
;; (define servicefolder (a ~/ "tmp/cj-qemucontrol/"))
