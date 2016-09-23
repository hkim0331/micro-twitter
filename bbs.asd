#|
  This file is a part of bbs project.
|#

(in-package :cl-user)
(defpackage bbs-asd
  (:use :cl :asdf))
(in-package :bbs-asd)

(defsystem bbs
:version "2.1.2"
  :author "hkimura"
  :license "free"
  :depends-on (:hunchentoot
               :hunchensocket
               :cl-who
               :cl-ppcre)
  :components ((:module "src"
                :components
                ((:file "bbs"))))
  :description "class room bbs system"
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
  :in-order-to ((test-op (test-op bbs-test))))
