#!/bin/nsh
nexec $1 netstat -na|egrep "LISTENING|Proto"|sed 's/:/ /g'|grep -v "\["