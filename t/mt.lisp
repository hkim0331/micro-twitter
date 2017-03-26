(in-package :cl-user)
(defpackage mt-test
  (:use :cl
        :mt
        :prove))
(in-package :mt-test)

;; NOTE: To run this test file, execute `(asdf:test-system :mt)' in your Lisp.

(plan nil)

;; blah blah blah.

(finalize)
