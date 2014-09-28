#!/bin/nsh
#
# Copyright (C) 2006 BladeLogic, Inc.
#
# script:  sqlserver_cis_compliance.nsh 
#
# Description: Gets information for SQL Server compliance
#######################################################################
#  MODIFY DATE   MODIFIED BY     REASON FOR & DESCRIPTION OF MODIFICATION
#  -----------  -------------    ----------------------------------------
#  07/10/06      David Balzotti   Created
#  08/08/07      Maria Cabral     Added ‘nexec’ command.
#  10/09/08      Maria Cabral     Fix defect: 25144
#  12/08/08      Maria Cabral     Fixed Database tag (add DB_ prefix).
#
########################################################################             
#
# Init variables
#
#########################################################################
#
# Get the required input
#
if [ $# -eq 5 ]
then
	HOST=$1
	INSTANCE_NAME=$2
	SQL_SERVER_USER=$3
	SQL_SERVER_PASSWORD=$4
	SQL_SERVER_HOMEDIR=$5
else
	echo "<Usage>sqlserver_cis_compliance.nsh HOST INSTANCE_NAME SQL_SERVER_USER SQL_SERVER_PASSWORD SQL_SERVER_HOMEDIR</Usage>"
	exit 0
fi

echo "<SQLSERVER-INSTANCES>"

if [ -d "//$HOST$SQL_SERVER_HOMEDIR" ]
then

 # Set up the instances variables
 # If the SQL_SERVER_INSTANCE passed in is localhost, just use localhost in the query
 #
 if [ "$INSTANCE_NAME" = "default" ] ; then
  INSTANCE_NAME="DEFAULT"
  SERVER="$HOST"
  
  # Test whether the service is available with a simple query 
  #
  RESULT=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "select @@VERSION" | sed '2,5d'`
  echo $RESULT | grep -q -e "not exist" -e "access denied"
    if [ $? -ne 0 ]; then
      echo "<$INSTANCE_NAME>"
        echo "<DATABASES>"
          DB_LIST=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "set nocount on select name from sysdatabases" -w 300 | tr -d '[:cntrl:]'`
          for DB in $DB_LIST 
          do
		   echo "<`echo $DB | sed 's/^/DB_/'`>"
		   nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select * from sysfiles FOR XML AUTO, ELEMENTS" | tr -d '[:cntrl:]' | tr -d '[:space:]'
		   echo "<drives>"
		   echo "<datafiles>"
		   DATADRIVE=`nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select filename from sysfiles where name not like '%log%'" |  cut -d':' -f1` 
		   echo "$DATADRIVE"
		   echo "</datafiles>"
		   echo "<logfiles>"
		   LOGDRIVE=`nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select filename from sysfiles where name like '%log%'" | cut -d':' -f1 ` 
		   echo "$LOGDRIVE"
		   echo "</logfiles>"
		   echo "<program-files>"
		   PROGRAMDRIVE=`echo "$SQL_SERVER_HOMEDIR" | cut -d'/' -f2`
		   echo "$PROGRAMDRIVE"
		   echo "</program-files>"
		   if [ "$DATADRIVE" = "$LOGDRIVE" -o "$LOGDRIVE" = "$PROGRAMDRIVE" -o "$DATADRIVE" = "$PROGRAMDRIVE" ] ; then
			echo "<volumes:different>"
			echo "FALSE"
			echo "</volumes:different>"
		   else
			echo "<volumes:different>"
			echo "TRUE"
			echo "</volumes:different>"           
		   fi
		   echo "</drives>"
		   echo "</`echo $DB | sed 's/^/DB_/'`>"
          done           
        echo "</DATABASES>"
                 
        nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_configure" -w 400 | sed '2d' | sed 's/[ ]*,/,/g'| csv2xml -1 -x | sed 's/csv2xml/CONFIGURATION-SETTINGS/g' | sed 's/record/SETTING/g'
        nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_helpextendedproc" -w 400 | sed '2d' | sed 's/[ ]*//g'| csv2xml -1 -x | sed 's/csv2xml/EXTENDED-STORED-PROCEDURES/g' | sed 's/record/EXTENDED-PROC/g'
      echo "</$INSTANCE_NAME>"      
    else
      echo "<$INSTANCE_NAME>"
       echo "<STATUS>The $SERVER instance is unavailable</STATUS>"
      echo "</$INSTANCE_NAME>"      
    fi
     
 elif [ "$INSTANCE_NAME" = "" ] ; then

   # Use net start to get a list of the running instances on the server
   for i in `nexec "$HOST" net start | grep MSSQL | sed 's/MSSQL\\$//g' | sed 's/^   //g' | sed 's/.$/ /' | tr -d '[:cntrl:]'` 
   do
     if [ "$i" = "MSSQLSERVER" ] ; then
       INSTANCE_NAME="DEFAULT"
       SERVER="$HOST"
       # Test whether the service is available with a simple query 
       #
       RESULT=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "select @@VERSION" | sed '2,5d'`
       echo $RESULT | grep -q -e "not exist" -e "access denied"
       if [ $? -ne 0 ]; then
         echo "<$INSTANCE_NAME>"
           echo "<DATABASES>"
            DB_LIST=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "set nocount on select name from sysdatabases" -w 300 | tr -d '[:cntrl:]'`
            for DB in $DB_LIST 
	    do
		   echo "<`echo $DB | sed 's/^/DB_/'`>"
		   nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select * from sysfiles FOR XML AUTO, ELEMENTS" | tr -d '[:cntrl:]' | tr -d '[:space:]'
		   echo "<drives>"
		   echo "<datafiles>"
		   DATADRIVE=`nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select filename from sysfiles where name not like '%log%'" |  cut -d':' -f1` 
		   echo "$DATADRIVE"
		   echo "</datafiles>"
		   echo "<logfiles>"
		   LOGDRIVE=`nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select filename from sysfiles where name like '%log%'" | cut -d':' -f1 ` 
		   echo "$LOGDRIVE"
		   echo "</logfiles>"
		   echo "<program-files>"
		   PROGRAMDRIVE=`echo "$SQL_SERVER_HOMEDIR" | cut -d'/' -f2`
		   echo "$PROGRAMDRIVE"
		   echo "</program-files>"
		   if [ "$DATADRIVE" = "$LOGDRIVE" -o "$LOGDRIVE" = "$PROGRAMDRIVE" -o "$DATADRIVE" = "$PROGRAMDRIVE" ] ; then
			echo "<volumes:different>"
			echo "FALSE"
			echo "</volumes:different>"
	           else
			echo "<volumes:different>"
			echo "TRUE"
			echo "</volumes:different>"           
		   fi
		   echo "</drives>"
		   echo "</`echo $DB | sed 's/^/DB_/'`>"
            done           
           echo "</DATABASES>"
            nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_configure" -w 400 | sed '2d' | sed 's/[ ]*,/,/g'| csv2xml -1 -x | sed 's/csv2xml/CONFIGURATION-SETTINGS/g' | sed 's/record/SETTING/g'
            nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_helpextendedproc" -w 400 | sed '2d' | sed 's/[ ]*//g'| csv2xml -1 -x | sed 's/csv2xml/EXTENDED-STORED-PROCEDURES/g' | sed 's/record/EXTENDED-PROC/g'
         echo "</$INSTANCE_NAME>"      
        else
         echo "<$INSTANCE_NAME>"
          echo "<STATUS>The $SERVER instance is unavailable</STATUS>"
         echo "</$INSTANCE_NAME>"      
        fi

     else
       INSTANCE_NAME="$i"
       SERVER="${HOST}\\${INSTANCE_NAME}"
       # Test whether the service is available with a simple query 
       RESULT=`nexec "$HOST" osql -Usa -Psa -S "$SERVER" -r -h-1 -Q "select @@VERSION" | sed '2,5d'`
       echo $RESULT | grep -q -e "not exist" -e "access denied"
       if [ $? -ne 0 ]; then
         echo "<$INSTANCE_NAME>"
           echo "<DATABASES>"
            DB_LIST=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "set nocount on select name from sysdatabases" -w 300 | tr -d '[:cntrl:]'`
            for DB in $DB_LIST 
            do
		   echo "<`echo $DB | sed 's/^/DB_/'`>"
		   nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select * from sysfiles FOR XML AUTO, ELEMENTS" | tr -d '[:cntrl:]' | tr -d '[:space:]'
		   echo "<drives>"
		   echo "<datafiles>"
		   DATADRIVE=`nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select filename from sysfiles where name not like '%log%'" |  cut -d':' -f1` 
		   echo "$DATADRIVE"
		   echo "</datafiles>"
		   echo "<logfiles>"
		   LOGDRIVE=`nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select filename from sysfiles where name like '%log%'" | cut -d':' -f1 ` 
		   echo "$LOGDRIVE"
		   echo "</logfiles>"
		   echo "<program-files>"
		   PROGRAMDRIVE=`echo "$SQL_SERVER_HOMEDIR" | cut -d'/' -f2`
		   echo "$PROGRAMDRIVE"
		   echo "</program-files>"
		   if [ "$DATADRIVE" = "$LOGDRIVE" -o "$LOGDRIVE" = "$PROGRAMDRIVE" -o "$DATADRIVE" = "$PROGRAMDRIVE" ] ; then
			echo "<volumes:different>"
			echo "FALSE"
			echo "</volumes:different>"
		   else
			echo "<volumes:different>"
			echo "TRUE"
			echo "</volumes:different>"           
		   fi
		   echo "</drives>"
		   echo "</`echo $DB | sed 's/^/DB_/'`>"
           done           
           echo "</DATABASES>"
            nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_configure" -w 400 | sed '2d' | sed 's/[ ]*,/,/g'| csv2xml -1 -x | sed 's/csv2xml/CONFIGURATION-SETTINGS/g' | sed 's/record/SETTING/g'
          nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_helpextendedproc" -w 400 | sed '2d' | sed 's/[ ]*//g'| csv2xml -1 -x | sed 's/csv2xml/EXTENDED-STORED-PROCEDURES/g' | sed 's/record/EXTENDED-PROC/g'
         echo "</$INSTANCE_NAME>"
       else
         echo "<$INSTANCE_NAME>"
          echo "<STATUS>The $SERVER instance is unavailable</STATUS>"
         echo "</$INSTANCE_NAME>"      
       fi      
     fi
   done
 else
   SERVER="${HOST}\\${INSTANCE_NAME}"
     # Test whether the service is available with a simple query 
     RESULT=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "select @@VERSION" | sed '2,5d'`
     echo $RESULT | grep -q -e "not exist" -e "access denied"
     if [ $? -ne 0 ]; then
     echo "<$INSTANCE_NAME>"

       echo "<DATABASES>"
         DB_LIST=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "set nocount on select name from sysdatabases" -w 300 | tr -d '[:cntrl:]'`
         for DB in $DB_LIST 
         do
		   echo "<`echo $DB | sed 's/^/DB_/'`>"
		   nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select * from sysfiles FOR XML AUTO, ELEMENTS" | tr -d '[:cntrl:]' | tr -d '[:space:]'
		   echo "<drives>"
		   echo "<datafiles>"
		   DATADRIVE=`nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select filename from sysfiles where name not like '%log%'" |  cut -d':' -f1` 
		   echo "$DATADRIVE"
		   echo "</datafiles>"
		   echo "<logfiles>"
		   LOGDRIVE=`nexec "$HOST" osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $SERVER -d $DB -r -h-1 -Q "set nocount on select filename from sysfiles where name like '%log%'" | cut -d':' -f1 ` 
		   echo "$LOGDRIVE"
		   echo "</logfiles>"
		   echo "<program-files>"
		   PROGRAMDRIVE=`echo "$SQL_SERVER_HOMEDIR" | cut -d'/' -f2`
		   echo "$PROGRAMDRIVE"
		   echo "</program-files>"
		   if [ "$DATADRIVE" = "$LOGDRIVE" -o "$LOGDRIVE" = "$PROGRAMDRIVE" -o "$DATADRIVE" = "$PROGRAMDRIVE" ] ; then
			echo "<volumes:different>"
			echo "FALSE"
			echo "</volumes:different>"
	           else
			echo "<volumes:different>"
			echo "TRUE"
			echo "</volumes:different>"           
		   fi
		   echo "</drives>"
		   echo "</`echo $DB | sed 's/^/DB_/'`>"
         done           
       echo "</DATABASES>"
       nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_configure" -w 400 | sed '2d' | sed 's/[ ]*,/,/g'| csv2xml -1 -x | sed 's/csv2xml/CONFIGURATION-SETTINGS/g' | sed 's/record/SETTING/g'
       nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_helpextendedproc" -w 400 | sed '2d' | sed 's/[ ]*//g'| csv2xml -1 -x | sed 's/csv2xml/EXTENDED-STORED-PROCEDURES/g' | sed 's/record/EXTENDED-PROC/g'
     echo "</$INSTANCE_NAME>"
       else
         echo "<$INSTANCE_NAME>"
          echo "<STATUS>The $SERVER instance is unavailable</STATUS>"
         echo "</$INSTANCE_NAME>"      
     fi      
 fi

else
  echo "<MSQLServer_Directory>//$HOST$SQL_SERVER_HOMEDIR directory is not found!!!</MSQLServer_Directory>"
fi
echo "</SQLSERVER-INSTANCES>"
