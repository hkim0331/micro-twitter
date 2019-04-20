# micro twitter

A small twitter like app for hkimura class.

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

* 2019-04-20 [5.0] cancel 4.*, restart from 5.0
* 2019-04-20 [4.1] define my-getenv

---
hkimura, 2019-04-20.
