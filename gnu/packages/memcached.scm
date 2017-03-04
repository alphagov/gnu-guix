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

(define-module (gnu packages memcached)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages cyrus-sasl)
  #:use-module ((guix licenses) #:prefix license:))

(define-public memcached
  (package
    (name "memcached")
    (version "1.4.35")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://memcached.org/files/memcached-" version ".tar.gz"))
       (sha256
        (base32 "0xll8rhinv30f6qpbr5zqdw2nfsk20ha382j00v0yv50bb4mm0gl"))))
    (build-system gnu-build-system)
    (inputs
     `(("libevent" ,libevent)
       ("cyrus-sasl" ,cyrus-sasl)))
    (home-page "https://memcached.org/")
    (synopsis "In memory caching service")
    (description "Memcached is a in memory key value store.  It has a small
and generic API, and was originally intended for use with dynamic web
applications.")
    (license license:bsd-3)))
