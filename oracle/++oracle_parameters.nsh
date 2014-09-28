#!/bin/nsh 
# 
# Copyright (C) 2009 BladeLogic, Inc.
#
# script:  oracle_sga.nsh 
#
# Description: This script displays Oracle sga information
#              Copies the sql script to the server, and nexec's the script,
#	       and removes when done.  Note that you need to set the
#	       dba user and password for the database server.  Note
#	       that this extended object uses a dbxml.gm grammar to 
#	       display the results.
#     
#
# Init variables
#
########################################################################

HOST=$1
ORACLE_HOME=$2
ORACLE_SID=$3
ORACLE_HOME_USER=$4
ORACLE_DB_USER=$5
ORACLE_DB_PASSWORD=$6

#echo '<SGA>'

if [ -z $ORACLE_HOME_USER ] ; then
#  echo ERROR: incorrect usage - $0 HOST ORACLE_HOME ORACLE_SID ORACLE_HOME_USER :
  ORexit 0
fi

if [ -z $ORACLE_DB_USER ] ; then
#  echo '<warning>No Oracle user given, using connect / as sysdba </warning>'
  ORACLE_DB_PASSWORD=" as sysdba"
fi

#echo '<info>'Running with HOST: $HOST ORACLE_HOME: $ORACLE_HOME ORACLE_SID: $ORACLE_SID ORACLE_HOME_USER: $ORACLE_HOME_USER '</info>'

# Copy the sql script to the server, and execute.

sed -n '/^# set heading/,/# --END/p' "$0" | sed 's/# //' > //${HOST}/tmp/$$.sql

if [ -f //$HOST/$ORACLE_HOME/bin/sqlplus ] ; then
  SQLPLUS=$ORACLE_HOME/bin/sqlplus 
else
#  echo '<warning>' $ORACLE_HOME/bin/sqlplus not found, using sqlplus in the path '</warning>'
  SQLPLUS=sqlplus
fi

nexec $HOST "su - $ORACLE_HOME_USER > /tmp/$$.su.out << EOF
#echo here
ORACLE_SID=$ORACLE_SID
export ORACLE_SID
id
$SQLPLUS -S /nolog @/tmp/$$.sql > /tmp/$$.sql.out 2> /dev/null
exit
EOF"
cat  //${HOST}/tmp/$$.sql.out 2> /dev/null

#echo '<su_out>'
#cat  //${HOST}/tmp/$$.su.out
#echo '</su_out>'

# sqlplus -s ${ORACLE_DB_USER}/${ORACLE_DB_PASSWORD} @$$.sql | sed -n '/<ORACLE-CONFIGURATION>/,/<\/ORACLE-CONFIGURATION>/p' | \
#                                                                         sed 's/[\<\/]*ROWSET\>//g' | sed 's/[\<\/]*DATAFILE\>//g'

# Remove the sql script from the server once the resultset has been returned.

#rm -f //${HOST}/$$.sql
rm -f //${HOST}/$$.su.out
rm -f //${HOST}/$$.sql.out

#echo '</SGA>'


# set heading off;
# set feedback off;
# set long 500000;
# set linesize 30000;
# set pagesize 50000;
# 
#connect / as sysdba
#select num||','||name||','||type||','||isdefault from v$parameter; 
#exit;
# --END SQL SCRIPT
