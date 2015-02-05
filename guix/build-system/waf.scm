;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Ricardo Wurmus <rekado@elephly.net>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (guix build-system waf)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (guix derivations)
  #:use-module (guix build-system)
  #:use-module (guix build-system gnu)
  #:use-module ((guix build-system python)
                #:select (default-python default-python2))
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-26)
  #:export (waf-build
            waf-build-system))

;; Commentary:
;;
;; Standard build procedure for applications using 'waf'.  This is very
;; similar to the 'python-build-system' and is implemented as an extension of
;; 'gnu-build-system'.
;;
;; Code:

(define* (lower name
                #:key source inputs native-inputs outputs system target
                (python (default-python))
                #:allow-other-keys
                #:rest arguments)
  "Return a bag for NAME."
  (define private-keywords
    '(#:source #:target #:python #:inputs #:native-inputs))

  (and (not target)                               ;XXX: no cross-compilation
       (bag
         (name name)
         (system system)
         (host-inputs `(,@(if source
                              `(("source" ,source))
                              '())
                        ,@inputs

                        ;; Keep the standard inputs of 'gnu-build-system'.
                        ,@(standard-packages)))
         (build-inputs `(("python" ,python)
                         ,@native-inputs))
         (outputs outputs)
         (build waf-build) ; only change compared to 'lower' in python.scm
         (arguments (strip-keyword-arguments private-keywords arguments)))))

(define* (waf-build store name inputs
                       #:key
                       (tests? #t)
                       (test-target "check")
                       (configure-flags ''())
                       (phases '(@ (guix build waf-build-system)
                                   %standard-phases))
                       (outputs '("out"))
                       (search-paths '())
                       (system (%current-system))
                       (guile #f)
                       (imported-modules '((guix build waf-build-system)
                                           (guix build gnu-build-system)
                                           (guix build utils)))
                       (modules '((guix build waf-build-system)
                                  (guix build utils))))
  "Build SOURCE with INPUTS.  This assumes that SOURCE provides a 'waf' file
as its build system."
  (define builder
    `(begin
       (use-modules ,@modules)
       (waf-build #:name ,name
                  #:source ,(match (assoc-ref inputs "source")
                              (((? derivation? source))
                               (derivation->output-path source))
                              ((source)
                               source)
                              (source
                               source))
                  #:configure-flags ,configure-flags
                  #:system ,system
                  #:test-target ,test-target
                  #:tests? ,tests?
                  #:phases ,phases
                  #:outputs %outputs
                  #:search-paths ',(map search-path-specification->sexp
                                        search-paths)
                  #:inputs %build-inputs)))

  (define guile-for-build
    (match guile
      ((? package?)
       (package-derivation store guile system #:graft? #f))
      (#f                                         ; the default
       (let* ((distro (resolve-interface '(gnu packages commencement)))
              (guile  (module-ref distro 'guile-final)))
         (package-derivation store guile system #:graft? #f)))))

  (build-expression->derivation store name builder
                                #:inputs inputs
                                #:system system
                                #:modules imported-modules
                                #:outputs outputs
                                #:guile-for-build guile-for-build))

(define waf-build-system
  (build-system
    (name 'waf)
    (description "The standard waf build system")
    (lower lower)))

;;; waf.scm ends here
