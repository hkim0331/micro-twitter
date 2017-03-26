#!/bin/sh

if [ $# -ne 1 ]; then
    echo usage: $0 VERSION
    exit
fi
VERSION=$1
TODAY=`date +%F`

if [ `uname` = 'Darwin' -a -e /usr/local/bin/gsed ]; then
    SED=/usr/local/bin/gsed
else
    SED=sed
fi

${SED} -i.bak "/(defvar \*version\*/ c\
(defvar *version* \"${VERSION}\")" src/mt.lisp

${SED} -i.bak "/:version / c\
  :version \"${VERSION}\"" mt.asd

${SED} -i.bak "/^hkimura, / c\
hkimura, ${TODAY}." README.md


echo ${VERSION} > VERSION
