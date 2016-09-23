#|
copyright (c) 2017 Hiroshi Kimura.

simple bbs on classroom based on hunchensocket demo.

* 2016-05-23: CHANGED 使用ポートはデフォルトで 20154 と 20155。

* 2016-05-23 CHANGED
  20154 と 20155 を使うように変更。
  C-2G の NAT の内側から bbs.melt にリクエスト行ったら kodama-1 に跳ね返す。
  komada-1 にも bbs を動かしておき、
  そちらはプロキシーなしの hunchentoot ダイレクトなので、
  ユーザの第４オクテットは端末のそれとなる。

* 2016-09-23 書き直し
  あまり変わってないか？ /on と /off で IP 表示のオンとオフ。

|#

(in-package :cl-user)
(defpackage bbs
  (:use :cl :hunchentoot :cl-who :cl-ppcre))
(in-package :bbs)

(defvar *version* "2.0")

(defvar *tweets* "")
(defvar *tweet-max* 140)
(defvar *http-port* 20154)
(defvar *ws-port*   20155)
(defvar *my-addr*)
(defvar *ws-uri*)

(defvar *c-2b* "10.28.100.200")
(defvar *c-2g* "10.28.102.200")
(defvar *kodama-1* "10.27.104.1")

(defvar *display-ip* nil)

(defvar *http-server*)
(defvar *ws-server*)

(defmacro navi ()
  `(htm
    "[ "
    (:a :href "http://robocar-2016.melt.kyutech.ac.jp" "robocar")
    " | "
    (:a :href "http://www.melt.kyutech.ac.jp" "hkimura labo.")
    " ]"
    ))

(setf (html-mode) :html5)

(defmacro standard-page (&body body)
  `(with-html-output-to-string
       (*standard-output* nil :prologue t :indent t)
     (:html
      :lang "ja"
      (:head
       (:meta :charset "utf-8")
       (:meta :http-equiv "X-UA-Compatible" :content "IE=edge")
       (:meta :name "viewport" :content "width=device-width, initial-scale=1.0")
       (:title "bulletin board system")
       (:link :rel "stylesheet"
              :href "//netdna.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css")
       (:link :rel "stylesheet" :href "/bbs.css"))
      (:body
       (:div
        :class "container"
        (:h1 :class "page-header hidden-xs" "Micro Twitter for Hkimura Class")
        (navi)
        ,@body
        (:hr)
        (:span
         (format t "programmed by hkimura, release ~a." *version*)))
       (:script :src "https://code.jquery.com/jquery.js")
       (:script :src "https://netdna.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js")
       (:script :src "/bbs.js")))))

(defun getenv (name &optional default)
  "Obtains the current value of the POSIX environment variable NAME."
  (declare (type (or string symbol) name))
  (let ((name (string name)))
    (or #+abcl (ext:getenv name)
        #+ccl (ccl:getenv name)
        #+clisp (ext:getenv name)
        #+cmu (unix:unix-getenv name) ; since CMUCL 20b
        #+ecl (si:getenv name)
        #+gcl (si:getenv name)
        #+mkcl (mkcl:getenv name)
        #+sbcl (sb-ext:posix-getenv name)
        default)))

(cond
  ((string= (getenv "BBS") "production")
   (setq *my-addr* "localhost")
   (setq *ws-uri* "ws://bbs.melt.kyutech.ac.jp/bbs"))
  ((string= (getenv "BBS") "isc")
   (setq *my-addr* *kodama-1*)
   (setq *ws-uri* (format nil "ws://~a:~a/bbs" *my-addr* *ws-port*)))
  (t (setq *my-addr* "localhost")
     (setq *ws-uri* (format nil "ws://~a:~a/bbs" *my-addr* *ws-port*))))

(defclass chat-room (hunchensocket:websocket-resource)
  ((name :initarg :name
         :initform (error "Name this room!")
         :reader name))
  (:default-initargs :client-class 'user))

(defclass user (hunchensocket:websocket-client)
  ((name :initarg :user-agent
         :reader name
         :initform (error "Name this user!"))))

(defvar *chat-rooms* (list (make-instance 'chat-room :name "/bbs")))

(defun find-room (request)
  (find (script-name request) *chat-rooms* :test #'string= :key #'name))

(defun broadcast (room message &rest args)
  (let ((m (apply #'format nil message args)))
    (loop for peer in (hunchensocket:clients room)
       do (hunchensocket:send-text-message peer m))))

;; 未実装:
;; メッセージの中身を timeline の先頭にくっつけ、
;; timeline の先頭から n 個を取り出し、
;; 文字列に変換して返す。あるいは json で構造つけて返す。
(defmethod hunchensocket:text-message-received ((room chat-room) user message)
  (broadcast room "~a" *tweets*))

(pushnew 'find-room hunchensocket:*websocket-dispatch-table*)

(defun now ()
  (multiple-value-bind
        (second minute hour)
      (get-decoded-time)
    (format nil "~2,'0d:~2,'0d:~2,'0d"
            hour
            minute
            second)))

(define-easy-handler (submit :uri "/submit") (tweet)
  (when (and
         (< (length tweet) *tweet-max*)
         (cl-ppcre:scan "\\S" tweet)
         (not (cl-ppcre:scan "(.)\\1{4,}$" tweet))
         (not (cl-ppcre:scan "おっぱい" tweet)))
    (setf *tweets*
          (format nil
                  "<span><span class=\"date\">~a[~a]</span> ~a</span><hr>~a"
                  (now)
                  ;; クライアントIPの第4オクテットをメッセージに追加。
                  ;; リバースプロキシーでは無駄になるが。
                  (if *display-ip*
                      (cl-ppcre:scan-to-strings "[0-9]*$" (remote-addr*))
                      "")
                  (escape-string tweet)
                  *tweets*)))
  (redirect "/index"))

(define-easy-handler (index :uri "/index") ()
  (standard-page
    (:form :action "/submit"  :method "post"
           ;; static/bbs.js uses this value.
           (:input :id "ws" :type "hidden" :value *ws-uri*)
           (:input :id "tweet" :name "tweet" :placeholder "つぶやいてね"))
    (:h3 "Messages")
    (:div :id "timeline" (format t "~a" *tweets*))
    ;; javascript fill the contents. which is better?
    ;;(:div :id "timeline")
    ))

(define-easy-handler (reset :uri "/reset") ()
  (setf *tweets* "")
  (redirect "/index"))

(define-easy-handler (on :uri "/on") ()
  (setf *display-ip* t)
  (redirect "/index"))

(define-easy-handler (off :uri "/off") ()
  (setf *display-ip* nil)
  (redirect "/index"))

(defun start-server ()
  (push (create-static-file-dispatcher-and-handler
         "/robots.txt" "static/robots.txt") *dispatch-table*)
  (push (create-static-file-dispatcher-and-handler
         "/bbs.css" "static/bbs.css") *dispatch-table*)
  (push (create-static-file-dispatcher-and-handler
         "/bbs.js" "static/bbs.js") *dispatch-table*)
  (setf *http-server*
        (make-instance 'easy-acceptor
                       :address *my-addr* :port *http-port*))
  (setf *ws-server*
        (make-instance 'hunchensocket:websocket-acceptor
                       :address *my-addr* :port *ws-port*))
  (start *http-server*)
  (start *ws-server*)
  (format t "http://~a:~d/index~%" *my-addr* *http-port*)
  (format t "~a~%" *ws-uri*))

(defun stop-server ()
  (format t "~a~%~a" (stop *http-server*) (stop *ws-server*)))

;; when production(sbcl), use this main defined.
(defun main ()
  (start-server)
  (loop (sleep 60)))
