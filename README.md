# micro twitter

A small twitter like app for hkimura class.

## [5.4] - 2020-05-21
* (ccl:getenv) を利用可能に。
* MT_WD 環境変数の導入。systemd で環境変数を与えて起動させる。

## 2020-05-15

ws://127.0.0.1:8001/ws に変更。

$ ros build mt.ros


## NOTE

MT_DEBUG=ws://127.0.0.1/ws when debug.
(in fish, set -x MT_DEBUG ws://127.0.0.1/ws)


## TODO

* keep log
* docker?

## Installation

* static folder must exist beside bbs binary. Use symbolic link if necessary.

## develop

```sh
CL-USER> (ql:quickload :mt)
CL-USER> (in-package :mt)
mt> (start-server)
```

## Usage

in the installed directory,

```sh
$ make start
```

or, when update,

```sh
$ make restart
```

then open uri,

```
http://localhost:8000/
```

websocket waits for connection at,

```
ws://localhost:8001/mt
```

## hidden errors

（折り曲げています）

```
127.0.0.1 hkimura [2019-04-20 13:40:28] "POST /submit HTTP/1.1" 302 322 "http://localhost:8000/"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit 605.1.15 (KHTML, like Gecko) Version/12.1 Safari/605.1.15"
127.0.0.1 hkimura [2019-04-20 13:40:28] "GET / HTTP/1.1" 200 1420 "http://localhost:8000/"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Safari/605.1.15"
[2019-04-20 13:40:28 [ERROR]] Error: end of file on #<SB-SYS:FD-STREAM for "socket 127.0.0.1:8001,
  peer: 127.0.0.1:64971" {100520EC03}>
[2019-04-20 13:40:28 [ERROR]] Error while processing connection: couldn't read from #<SB-SYS:FD-STREAM
  for "socket 127.0.0.1:8001, peer: 127.0.0.1:64971" {100520EC03}>:
  Connection reset by peer
127.0.0.1 - [2019-04-20 13:40:28] "GET /mt HTTP/1.1" 101 0 "-"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Safari/605.1.15"
```

## ChangeLog

* 2019-04-20 [4.1] define my-getenv
* 2019-04-20 [5.0] cancel 4.*, restart from 5.0
* 2019-04-20 [5.2.1] ws-uri は ws://127.0.0.1/mt などじゃダメ。
  外に見せる ws のアドレスじゃなくちゃ。 ws://mt.hkim.jp/mt が正しい。
* 2019-04-21 [5.3]
  * roswell script
  * real-remote-addr
  * (fish) set -x MT_DEBUG ws://127.0.0.1/ws
  * tweets のフォーマット変更。メッセージよりも tweets にするか。

---
hkimura, 2020-05-21.
