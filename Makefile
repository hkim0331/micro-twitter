src/bbs:
	sbcl --eval "(ql:quickload :bbs)" --eval "(in-package :bbs)" \
	--eval "(sb-ext:save-lisp-and-die \"src/bbs\" :executable t :toplevel 'main)"

restart: stop clean start

start: src/bbs
	nohup ./src/bbs &

# FIXME: date +%F is not enough.
stop:
	kill `ps ax | grep /bbs | head -1 | awk '{print $$1}'`
	mv nohup.out nohup.out.`date +%F`

clean:
	${RM} ./src/bbs nohup.out

