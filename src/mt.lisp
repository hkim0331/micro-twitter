#|
copyright (c) 2015-2017 Hiroshi Kimura.

simple mt on classroom based on hunchensocket demo.

* 2016-05-23: CHANGED 使用ポートはデフォルトで 20154 と 20155。

* 2016-05-23 CHANGED
  20154 と 20155 を使うように変更。
  C-2G の NAT の内側から mt.melt にリクエスト行ったら kodama-1 に跳ね返す。
  komada-1 にも mt を動かしておき、
  そちらはプロキシーなしの hunchentoot ダイレクトなので、
  ユーザの第４オクテットは端末のそれとなる。

* 2016-09-23 書き直し
  あまり変わってないか？
  /reset でメッセージ初期化。
  /on と /off で IP 表示のオンとオフ。

* 2016-09-26, ccl でバグの理由は？
  localhost を使うと IPv6 で接続しようとするのかな？

|#

(in-package :cl-user)
(defpackage mt
  (:use :cl :hunchentoot :cl-who :cl-ppcre))
(in-package :mt)

(defvar *version* "3.3")
(defvar *tweets* "")
(defvar *tweet-max* 140)
(defvar *http-port* 20154)
(defvar *ws-port*   20155) ;; can not use same port.
(defvar *my-addr*)
(defvar *ws-uri*)
(defvar *display-ip* nil)
(defvar *http-server*)
(defvar *ws-server*)
(defvar *kodama-1* "10.27.104.1")

;;; no use
;; (defvar *c-2b* "10.27.100.200")
;; (defvar *c-2g* "10.27.102.200")

(defmacro navi ()
  `(htm
    "[ "
    (:a :href "http://literacy.melt.kyutech.ac.jp" "literacy")
    " | "
    (:a :href "http://www.melt.kyutech.ac.jp" "hkimura labo.")
    " || "
    (:a :href "/on" "on")
    " | "
    (:a :href "/off" "off")
    " | "
    (:a :href "/reset" "reset")
    " ]"))

(defmacro standard-page (&body body)
  `(with-html-output-to-string
       (*standard-output* nil :prologue t :indent t)
     (:html
      :lang "ja"
      (:head
       (:meta :charset "utf-8")
       (:meta :http-equiv "X-UA-Compatible" :content "IE=edge")
       (:meta :name "viewport" :content "width=device-width, initial-scale=1.0")
       (:link :rel "stylesheet"
              :href "//netdna.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css")
       (:link :rel "stylesheet" :href "/my.css")
       (:title "bulletin board system"))
      (:body
       (:div :class "container"
        (:h1 :class "page-header hidden-xs" "Micro Twitter for Hkimura Class")
        (navi)
        ,@body
        (:hr)
        (:span
         (format t "programmed by hkimura, release ~a." *version*)))
       (:script :src "/my.js")))))

(defclass chat-room (hunchensocket:websocket-resource)
  ((name :initarg :name
         :initform (error "Name this room!")
         :reader name))
  (:default-initargs :client-class 'user))

(defclass user (hunchensocket:websocket-client)
  ((name :initarg :user-agent
         :reader name
         :initform (error "Name this user!"))))

(defvar *chat-rooms* (list (make-instance 'chat-room :name "/mt")))

(defun find-room (request)
  (find (script-name request) *chat-rooms* :test #'string= :key #'name))

(defun broadcast (room message &rest args)
  (let ((m (apply #'format nil message args)))
    (loop for peer in (hunchensocket:clients room)
       do (hunchensocket:send-text-message peer m))))

;; unuse variables user and message.
;; however,  Generic-function's definition is,
;; (HUNCHENSOCKET::RESOURCE
;;  HUNCHENSOCKET::CLIENT
;;  HUNCHENSOCKET::MESSAGE)
;; can not remove.
(defmethod hunchensocket:text-message-received ((room chat-room) user message)
  (broadcast room "~a"
             (if *display-ip* *tweets*
                 (cl-ppcre:regex-replace-all "\\[[0-9]*\\]" *tweets* "[ ]"))))

(pushnew 'find-room hunchensocket:*websocket-dispatch-table*)

(defun now ()
  (multiple-value-bind (second minute hour) (get-decoded-time)
    (format nil "~2,'0d:~2,'0d:~2,'0d" hour minute second)))

(define-easy-handler (submit :uri "/submit") (tweet)
  (format t "~a MT ~a~%" (remote-addr*) tweet)
  (when (and
         (< (length tweet) *tweet-max*)
         (cl-ppcre:scan "\\S" tweet)
         (not (cl-ppcre:scan "(.)\\1{4,}$" tweet))
         (not (cl-ppcre:scan "おっぱい" tweet)))
    (setf *tweets*
          (format
           nil
           "<span><span class=\"time\">~a[~a]</span> ~a</span><hr>~a"
           (now)
           (cl-ppcre:scan-to-strings "[0-9]*$" (remote-addr*))
           (escape-string tweet)
           *tweets*)))
  (redirect "/"))

(define-easy-handler (index :uri "/") ()
  (standard-page
    (:form :action "/submit"  :method "post"
           (:input :id "ws" :type "hidden" :value *ws-uri*)
           (:input :id "tweet" :name "tweet" :placeholder "つぶやいてね"))
           ;; (:textarea :id "tweet" :name "tweet" :placeholder "つぶやいてね"
           ;;            :rows 5 :cols 60)
           ;; (:br)
           ;; (:input :type "submit")

    (:h3 "Messages")
    (:div :id "timeline")))

(defun auth? ()
  (multiple-value-bind (user pass) (authorization)
    (and (string= user "hkimura") (string= pass "pass"))))

(define-easy-handler (reset :uri "/reset") ()
  (if (auth?)
      (progn
        (setf *tweets* "")
        (redirect "/"))
      (require-authorization)))

(define-easy-handler (on :uri "/on") ()
  (if (auth?)
      (progn
        (setf *display-ip* t)
        (redirect "/"))
      (require-authorization)))

(define-easy-handler (off :uri "/off") ()
  (if (auth?)
      (progn
        (setf *display-ip* nil)
        (redirect "/"))
      (require-authorization)))

(define-easy-handler (test :uri "/test") ()
  (standard-page
    (:h1 "It worked")))

(defun start-server ()
  (setf (html-mode) :html5)

  (push (create-static-file-dispatcher-and-handler
         "/robots.txt" "static/robots.txt") *dispatch-table*)
  (push (create-static-file-dispatcher-and-handler
         "/my.css" "static/my.css") *dispatch-table*)
  (push (create-static-file-dispatcher-and-handler
         "/my.js"  "static/my.js") *dispatch-table*)

  ;; check before installation
  (cond
    ((probe-file #p"/edu/")
     (setq *my-addr* *kodama-1*)
     (setq *ws-uri* (format nil "ws://~a:~a/mt" *my-addr* *ws-port*)))
    ((probe-file #p"/home/hkim")
     (setq *my-addr* "localhost")
     (setq *ws-uri* (format nil "ws://mt.melt.kyutech.ac.jp/mt")))
    ;; when use 'localhost' instead of '127.0.0.1' with ccl,
    ;; NOT WORK.
    (t (setq *my-addr* "127.0.0.1")
       (setq *ws-uri* (format nil "ws://~a:~a/mt" *my-addr* *ws-port*))))

  (setf *http-server*
        (make-instance 'easy-acceptor
                       :address *my-addr* :port *http-port*))
  (start *http-server*)
  (format t "http://~a:~d/~%" *my-addr* *http-port*)
  (setf *ws-server*
        (make-instance 'hunchensocket:websocket-acceptor
                       :address *my-addr* :port *ws-port*))
  (start *ws-server*)
  (format t "~a~%" *ws-uri*))

(defun stop-server ()
  (format t "~a~%~a" (stop *http-server*) (stop *ws-server*)))

;; when production(sbcl), use this main defined.
(defun main ()
  (start-server)
  (loop (sleep 60)))
