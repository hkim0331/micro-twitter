#|
  This file is a part of micro-twitter project.
|#

(in-package :cl-user)
(defpackage mt-asd
  (:use :cl :asdf))
(in-package :mt-asd)

(defsystem mt
:version "5.4"
  :author "hkimura"
  :license "free"
  :depends-on (:hunchentoot
               :hunchensocket
               :cl-who
               :cl-ppcre)
  :components ((:module "src"
                :components
                ((:file "mt"))))
  :description "classroom micro twitter"
  :long-description
  #.(with-open-file (stream (merge-pathnames
                             #p"README.markdown"
                             (or *load-pathname* *compile-file-pathname*))
                            :if-does-not-exist nil
                            :direction :input)
      (when stream
        (let ((seq (make-array (file-length stream)
                               :element-type 'character
                               :fill-pointer t)))
          (setf (fill-pointer seq) (read-sequence seq stream))
          seq)))
  :in-order-to ((test-op (test-op mt-test))))
