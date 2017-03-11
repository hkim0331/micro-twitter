# bbs

A small bbs for hkimura class.

## Installation

* static folder must exist beside bbs binary. Use symbolic link if necessary.

## develop

```
CL-USER> (ql:quickload :bbs)
CL-USER> (in-package :bbs)
BBS> (start-server)
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

## TODO

* cl-log

## DONE


---
hkimura.
