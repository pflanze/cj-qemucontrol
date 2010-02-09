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

(define servicename "windows2000")
(define diskpath "/dev/plain/windows2000")
(define redirections "-redir tcp:3022::22")
(define use-tablet #t)
(define win2k-hack? #t)
(define ram-MB 384)
(define soundhw #f)
