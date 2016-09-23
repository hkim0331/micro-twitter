#!/bin/sh

if [ $# -ne 1 ]; then
    echo usage: $0 VERSION
    exit
fi
VERSION=$1

if [ `uname` = 'Darwin' -a -e /usr/local/bin/gsed ]; then
    SED=/usr/local/bin/gsed
else
    SED=sed
fi

${SED} -i.bak "/(defvar \*version\*/ c\
(defvar *version* \"${VERSION}\")" src/bbs.lisp

${SED} -i.bak "/:version / c\
  :version \"${VERSION}\"" bbs.asd

echo ${VERSION} > VERSION
