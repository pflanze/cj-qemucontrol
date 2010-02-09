;; ---- settings

;; This is Scheme code;
;; booleans are #f for false and #t for true
;;  (actually all non-#f values are interpreted as true)

;; You can create definitions on your own, too (better start your own
;; variables with an underscore to avoid potential conflicts), and use
;; them in later ones, for example
;;  (define _basedir "/my/base/directory/")
;;  (define diskpath (string-append _basedir "hda.img"))
;;  instead of string-append you can also just use the letter a:
;;  (define diskpath (a _basedir "hda.img"))
;; You can prepend a string with your home directory by using the ~ function:
;;  (define diskpath (~ "images/hda")) ;; where images is a subdir of your home

;; By including this file into others (see the windows2000 and
;; windows2000-smp files as examples) you can adapt the settings
;; selectively to different usages.

;; If you want to see what is going to be executed in bash syntax,
;; then uncomment the following line:
;; (define dry-run? #t)

;; required settings:
(define servicename "windows2000")
(define diskpath "/dev/plain/windows2000")
(define ram-MB 384)

;; optional settings (can be removed or set to #f):
(define redirections "-redir tcp:3022::22")
(define use-tablet #t)
(define win2k-hack? #t)
(define soundhw #f)
;;(define virtual-memory-limit 1200000)

;; If you need to add random other options, you can use:
;; (add-options! "-someoptionwithvalue" "optionvalue")
;; or just
;; (add-options! "-someoptionwithoutvalue")
