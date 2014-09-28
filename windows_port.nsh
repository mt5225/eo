#!/bin/nsh
nexec $1 netstat -na|egrep "Proto"|sed 's/:/ /g'