#|
  This file is a part of micro-twitter project.
|#

(in-package :cl-user)
(defpackage mt-test-asd
  (:use :cl :asdf))
(in-package :mt-test-asd)

(defsystem mt-test
  :author "hiroshi kimura"
  :license "free"
  :depends-on (:mt
               :prove)
  :components ((:module "t"
                :components
                ((:test-file "mt"))))
  :description "Test system for mt"

  :defsystem-depends-on (:prove-asdf)
  :perform (test-op :after (op c)
                    (funcall (intern #.(string :run-test-system) :prove-asdf) c)
                    (asdf:clear-system c)))
