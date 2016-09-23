#|
  This file is a part of bbs project.
|#

(in-package :cl-user)
(defpackage bbs-test-asd
  (:use :cl :asdf))
(in-package :bbs-test-asd)

(defsystem bbs-test
  :author "hiroshi kimura"
  :license "free"
  :depends-on (:bbs
               :prove)
  :components ((:module "t"
                :components
                ((:test-file "bbs"))))
  :description "Test system for bbs"

  :defsystem-depends-on (:prove-asdf)
  :perform (test-op :after (op c)
                    (funcall (intern #.(string :run-test-system) :prove-asdf) c)
                    (asdf:clear-system c)))
