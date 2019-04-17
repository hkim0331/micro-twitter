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
http://localhost:20154/index
```

websocket waits for connection at,

```
ws://localhost:20155/bbs
```

---
hkimura, 2017-04-22.
