#|
copyright (c) 2015-2019 Hiroshi Kimura.

simple mt on classroom based on hunchensocket demo.

* 2019-04-15: 8000 と 8001 使おう。

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

(defun my-getenv (name &optional default)
    #+CMU
    (let ((x (assoc name ext:*environment-list*
                    :test #'string=)))
      (if x (cdr x) default))
    #-CMU
    (or
     #+Allegro (sys:getenv name)
     #+CLISP (ext:getenv name)
     #+ECL (si:getenv name)
     #+SBCL (sb-unix::posix-getenv name)
     #+LISPWORKS (lispworks:environment-variable name)
     default))

(defvar *version* "4.1")
(defvar *tweets* "")
(defvar *tweet-max* 140)
(defvar *http-port* 8000)
(defvar *ws-port*   8001) ;; can not use same port with *http-port*
(defvar *my-addr* (or (my-getenv "MT_ADDR") "127.0.0.1"))
(defvar *ws-uri* (format nil "ws://~a:~a/mt" *my-addr* *ws-port*))
(defvar *display-ip* nil)
(defvar *http-server*)
(defvar *ws-server*)

(defmacro navi ()
  `(htm
    "[ "
    (:a :href "https://hcc.hkim.jp" "情報学演習")
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
              :href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css"
              :integrity "sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T"
              :crossorigin "anonymous")
       (:link :rel "stylesheet" :href "/my.css")
       (:title "bulletin board system"))
      (:body
       :div :class "container"
       (:h1 :class "page-header hidden-xs" "Micro Twitter for hkimura Classes")
       (navi)
       ,@body
       (:hr)
       (:span
        (format t "programmed by hkimura, release ~a." *version*))
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
;;  (format t "~a MT ~a~%" (remote-addr*) tweet)
  (when (and
         (< 40 (length tweet) *tweet-max*)
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
