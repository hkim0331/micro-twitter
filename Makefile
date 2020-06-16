# mt:
# 	sbcl --eval "(ql:quickload :mt)" --eval "(in-package :mt)" \
# 	--eval "(sb-ext:save-lisp-and-die \"mt\" :executable t :toplevel 'main)"

mt:
	ros build mt.ros

restart: stop clean start

start: mt
	nohup ./mt &

stop:
	kill `ps ax | grep '[.]/mt' | head -1 | awk '{print $$1}'`
	mv nohup.out nohup.out.`date +%F_%T`

clean:
	${RM} ./mt *.bak src/*.bak


