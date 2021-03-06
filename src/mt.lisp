#|
copyright (c) 2015-2019 Hiroshi Kimura.

simple mt on classroom based on hunchensocket demo.

* 2020-05-21: getenv "HOME"

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

;;http://cl-cookbook.sourceforge.net/os.html
(defun my-getenv (name &optional default)
    #+CMU
    (let ((x (assoc name ext:*environment-list*
                    :test #'string=)))
      (if x (cdr x) default))
    #-CMU
    (or
     #+Allegro (sys:getenv name)
     #+CCL (ccl:getenv name)
     #+CLISP (ext:getenv name)
     #+ECL (si:getenv name)
     #+SBCL (sb-unix::posix-getenv name)
     #+LISPWORKS (lispworks:environment-variable name)))

(defvar *version* "5.5.1")
;;
;; これだとコンパイル時に決定する、か？
;;
(defvar *mt-http* 8000)
(defvar *mt-ws*   8001) ;; can not use same port with http.
(defvar *mt-addr* "127.0.0.1")
(defvar *mt-uri*  "ws://127.0.0.1:8001/mt")
(defvar *mt-wd*   "/Users/hkim/common-lisp/mt")

(defvar *tweets* "")
(defvar *tweet-max* 140)
(defvar *display-ip* nil)
(defvar *http-server*)
(defvar *ws-server*)

(defmacro navi ()
  `(htm
    (:p
     (:a :href "/on" :class "btn btn-outline-primary btn-sm" "on")
     " | "
     (:a :href "/off" :class "btn btn-outline-primary btn-sm" "off")
     " | "
     (:a :href "/reset" :class "btn btn-danger btn-sm" "reset"))))

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
              :href "https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css"
              :integrity "sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T"
              :crossorigin "anonymous")
       (:link :rel "stylesheet" :href "/my.css")
       (:title "bulletin board system"))
      (:body
       (:div :class "container"
        (:h3 :class "page-header hidden-xs" "Websocket example")
        (navi)
        ,@body
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
  (setf *tweets*
        (format nil "<span><span class='time'>from ~a, at ~a,</span><br> ~a</span><hr>~a"
                (real-remote-addr)
                (now)
                (if (or (< *tweet-max* (length tweet))
                        (cl-ppcre:scan "(.)\\1{4,}$" tweet)
                        (cl-ppcre:scan "おっぱい" tweet))
                    "長すぎるか、禁止ワードを含むメッセージです。"
                    (escape-string tweet))
                *tweets*))
  (redirect "/"))

(define-easy-handler (index :uri "/") ()
  (standard-page
    (:form :action "/submit"  :method "post"
           (:input :id "ws" :type "hidden" :value *mt-uri*)
           (:input :id "tweet" :name "tweet" :placeholder "つぶやいてね"))
    (:h3 "your tweets")
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
         "/robots.txt"
         (format nil "~a/static/robots.txt" *mt-wd*))
        *dispatch-table*)
  (push (create-static-file-dispatcher-and-handler
         "/my.css"
         (format nil "~a/static/my.css" *mt-wd*))
        *dispatch-table*)
  (push (create-static-file-dispatcher-and-handler
         "/my.js"
         (format nil "~a/static/my.js" *mt-wd*))
        *dispatch-table*)

  (setf *http-server*
        (make-instance 'easy-acceptor
                       :address *mt-addr*
                       :port *mt-http*))
  (start *http-server*)

  (setf *ws-server*
        (make-instance 'hunchensocket:websocket-acceptor
                       :address *mt-addr*
                       :port *mt-ws*))
  (start *ws-server*)

  (format t "version: ~a~%" *version*)
  (format t "http://~a:~d/~%" *mt-addr* *mt-http*)
  (format t "~a~%" *mt-uri*))

(defun stop-server ()
  (format t "~a~%~a" (stop *ws-server*) (stop *http-server*)))

;;https://stevelosh.com/blog/2018/07/fun-with-macros-if-let/
(defmacro when-let (binding &body body)
  (destructuring-bind ((symbol value)) binding
    `(let ((,symbol ,value))
      (when ,symbol
        ,@body))))

(defun init-constants ()
  (when-let ((port (my-getenv "MT_HTTP")))
    (setf *mt-http* (parse-integer port)))
  (when-let ((port (my-getenv "MT_WS")))
    (setf *mt-ws* (parse-integer port)))
  (when-let ((addr (my-getenv "MT_ADDR")))
    (setf *mt-addr* addr))
  (when-let ((uri (my-getenv "MT_URI")))
    (setf *mt-uri* uri))
  (when-let ((wd (my-getenv "MT_WD")))
    (setf *mt-wd* wd)))

(defun display-constants ()
  (format t "*mt-http* ~a~%" *mt-http*)
  (format t "*mt-ws* ~a~%"   *mt-ws*)
  (format t "*mt-addr* ~a~%" *mt-addr*)
  (format t "*mt-uri* ~a~%"  *mt-uri*)
  (format t "*mt-wd* ~a~%"   *mt-wd*))

;; when production(sbcl), use this main.
(defun main ()
  (init-constants)
  (display-constants)
  (start-server)
  (loop (sleep 60)))
