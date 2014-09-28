#!/bin/nsh
#
# Copyright (C) 2006 BladeLogic, Inc.
#
# script:  sqlserver_column_info.nsh 
#
# Description: This script displays Sql Server 2000 Column Information.
#              This queries the INFORMATION_SCHEMA views. You need to set the
#	       dba user and password for the database server.  Note
#	       that this extended object uses a dbxml.gm grammar to 
#	       display the results.
#             
#######################################################################
#  MODIFY DATE   MODIFIED BY     REASON FOR & DESCRIPTION OF MODIFICATION
#  -----------  -------------    ----------------------------------------
#  06/29/06      David Balzotti   Created
########################################################################             
#
# Init variables
#
#########################################################################

HOST=$1
SQL_SERVER_USER=$2
SQL_SERVER_PASSWORD=$3


DB_LIST=`nexec $HOST osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $HOST -r -h-1 -Q "set nocount on select name from sysdatabases" -w 300 | tr -d '[:cntrl:]'`
 

echo "<SQLSERVER-COLUMNS>"
for DB in $DB_LIST 
do
	if [[ "$DB" != "master" ]]; then

		echo "<$DB>"  
			nexec $HOST osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $HOST -r -h-1 -Q "set nocount on select * from ${DB}.information_schema.COLUMNS for XML AUTO, ELEMENTS" | tr -d '[:cntrl:]' | tr -d '[:space:]' | sed 's/[a-zA-z]*.information_schema.COLUMNS/Column/g'
		echo "</$DB>"

	fi
done

 
 echo "</SQLSERVER-COLUMNS>"
 
