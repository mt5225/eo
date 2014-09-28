#!/bin/nsh
nexec $1 net statistics server|egrep "0"
