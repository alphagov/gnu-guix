;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 Christopher Baines <mail@cbaines.net>
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

(define-module (gnu services memcached)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages memcached)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services)
  #:use-module (gnu system shadow)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guix modules)
  #:use-module (ice-9 match)
  #:export (memcached-service-type

            <memcached-configuration>
            memcached-configuration
            memcached-configuration?
            memcached-configuration-memecached
            memcached-configuration-interfaces
            memcached-configuration-tcp-port
            memcached-configuration-udp-port))

;;;
;;; Memcached
;;;

(define-record-type* <memcached-configuration>
  memcached-configuration make-memcached-configuration
  memcached-configuration?
  (memcached          memcached-configuration-memcached ;<package>
                      (default memcached))
  (interfaces         memcached-configuration-interfaces
                      (default '("127.0.0.1")))
  (tcp-port           memcached-configuration-tcp-port
                      (default 11211))
  (udp-port           memcached-configuration-udp-port
                      (default 11211))
  (additional-options memcached-configuration-additional-options
                      (default '())))

(define %memcached-accounts
  (list (user-group (name "memcached") (system? #t))
        (user-account
         (name "memcached")
         (group "memcached")
         (system? #t)
         (comment "Memcached server user")
         (home-directory "/var/empty")
         (shell (file-append shadow "/sbin/nologin")))))

(define memcached-shepherd-service
  (match-lambda
    (($ <memcached-configuration> memcached interfaces tcp-port udp-port
                                  additional-options)
     (with-imported-modules (source-module-closure
                             '((gnu build shepherd)))
       (list (shepherd-service
              (provision '(memcached))
              (documentation "Run the Memcached daemon.")
              (requirement '(user-processes loopback))
              (modules '((gnu build shepherd)))
              (start #~(make-forkexec-constructor
                        `(#$(file-append memcached "/bin/memcached")
                          "-l" #$(string-join interfaces ",")
                          "-p" #$(number->string tcp-port)
                          "-U" #$(number->string udp-port)
                          "-u" "memcached"
                          ,#$@additional-options)
                        #:log-file "/var/log/memcached"))
              (stop #~(make-kill-destructor))))))))

(define memcached-service-type
  (service-type (name 'memcached)
                (extensions
                 (list (service-extension shepherd-root-service-type
                                          memcached-shepherd-service)
                       (service-extension account-service-type
                                          (const %memcached-accounts))))))
