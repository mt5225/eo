#!/bin/nsh
#
# Copyright (C) 2007 BladeLogic, Inc.
#
# script:  sqlserver_compliance_config_info.nsh 
#
#             
#######################################################################
#  MODIFY DATE   MODIFIED BY     REASON FOR & DESCRIPTION OF MODIFICATION
#  -----------  -------------    ----------------------------------------
#  07/29/07      Maria Cabral     Created
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
	echo "<Usage>sqlserver_compliance_config_info.nsh HOST INSTANCE_NAME SQL_SERVER_USER SQL_SERVER_PASSWORD SQL_SERVER_HOMEDIR</Usage>"
	exit 0
fi


echo "<SQLSERVER_COMPLIANCE>"

if [ -d "//$HOST$SQL_SERVER_HOMEDIR" ]
then
 
  echo "<SQLSERVER_SECURITY_CONFIGURATION>"
   # GET Login Mode
   LMODe=`nexec "$HOST" \
   osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$HOST" -r -h-1 -Q "xp_loginconfig 'login mode'" | \
   awk '{print $3}'`
   echo "<Login_Mode>"
    echo " $LMODe"
   echo "</Login_Mode>"
  
    # GET Audit Level
   AUDIT_LEVEL=`nexec "$HOST" \
   osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$HOST" -r -h-1 -Q "xp_loginconfig 'audit level'" |\
   awk '{print $3}'`
   echo "<Audit_Level>"
    echo "$AUDIT_LEVEL"
   echo "</Audit_Level>"
  echo "</SQLSERVER_SECURITY_CONFIGURATION>"
  
  
  echo "<SQLSERVER_VERSION>"
  # Get Verson
  VRS=`nexec "$HOST" \
  osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$HOST" -r -h-1 -Q "set nocount on Select @@version" |\
  grep SQL | sed 's/-/=/; s/sysadmin//; s/.*rows.*//'`

  echo "<Microsoft_SQLServer_2000>"
  echo $VRS | cut -d = -f2 | while read VERSIOn
  do
    echo "$VERSIOn"
  done
  echo "</Microsoft_SQLServer_2000>"
  echo "</SQLSERVER_VERSION>"

 # Set up the instances variables and get Server Role and Sysusers
 echo "<SQLSERVER-INSTANCES>"
 # Set up the instances variables
 # If the SQL_SERVER_INSTANCE passed in is localhost, just use localhost in the query
 if [ "$INSTANCE_NAME" = "default" ] ; then
  INSTANCE_NAME="DEFAULT"
  SERVER="$HOST"
  
  # Test whether the service is available with a simple query 
  RESULT=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "select @@VERSION" | sed '2,5d'`
  echo $RESULT | grep -q -e "not exist" -e "access denied"
    if [ $? -ne 0 ]; then
      echo "<$INSTANCE_NAME>"
        echo "<DATABASES>"
          DB_LIST=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "set nocount on select name from sysdatabases" -w 300 | tr -d '[:cntrl:]'`
          for DB in $DB_LIST 
          do              
           if [ "$DB" != "master" -a "$DB" != "tempdb" ] ; then
             echo "<`echo $DB | sed 's/^/DB_/'`>"
              nexec "$HOST" osql -U sa -P sa -S "$SERVER" -d "$DB" -n -h-1  -Q  "set nocount on select name from sysusers for XML AUTO, ELEMENTS" -w 400 | tr -d '[:cntrl:]' | tr -d '[:space:]'
             echo "</`echo $DB | sed 's/^/DB_/'`>"
           fi
           done           
          echo "</DATABASES>"
            
       nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_helpsrvrolemember"  -w 400  | sed '2d' | \
              sed 's/.*rows.*//g' | awk '{print $1, $2}'  | sed 's/[ ]*//g' | sed 'N;$!P;$!D;$d'  | sed 's/\\/\\\\/' | csv2xml -1 -x | \
              sed 's/csv2xml/SERVER-ROLE/g' | sed 's/record/ROLE/g'       
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
       RESULT=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "select @@VERSION" | sed '2,5d'`
       echo $RESULT | grep -q -e "not exist" -e "access denied"
       if [ $? -ne 0 ]; then
         echo "<$INSTANCE_NAME>"
           echo "<DATABASES>"
            DB_LIST=`nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "set nocount on select name from sysdatabases" -w 300 | tr -d '[:cntrl:]'`
            for DB in $DB_LIST 
          do
           if [ "$DB" != "master" -a "$DB" != "tempdb" ] ; then
             echo "<USER_IDS_$DB>"
              nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -d "$DB" -n -h-1  -Q  "set nocount on select name from sysusers for XML AUTO, ELEMENTS" -w 400 | tr -d '[:cntrl:]' | tr -d '[:space:]'
             echo "</USER_IDS_$DB>"
           fi
           done           
          echo "</DATABASES>"
            
       nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_helpsrvrolemember"  -w 400  | sed '2d' | \
              sed 's/.*rows.*//g' | awk '{print $1, $2}'  | sed 's/[ ]*//g' | sed 'N;$!P;$!D;$d'  | sed 's/\\/\\\\/' | csv2xml -1 -x | \
              sed 's/csv2xml/SERVER-ROLE/g' | sed 's/record/ROLE/g'       
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
           if [ "$DB" != "master" -a "$DB" != "tempdb" ] ; then
             echo "<USER_IDS_$DB>"
              nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -d "$DB" -n -h-1  -Q  "set nocount on select name from sysusers for XML AUTO, ELEMENTS" -w 400 | tr -d '[:cntrl:]' | tr -d '[:space:]'
             echo "</USER_IDS_$DB>"
           fi
           done           
          echo "</DATABASES>"
            
       nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_helpsrvrolemember"  -w 400  | sed '2d' | \
              sed 's/.*rows.*//g' | awk '{print $1, $2}'  | sed 's/[ ]*//g' | sed 'N;$!P;$!D;$d'  | sed 's/\\/\\\\/' | csv2xml -1 -x | \
              sed 's/csv2xml/SERVER-ROLE/g' | sed 's/record/ROLE/g'       
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
           if [ "$DB" != "master" -a "$DB" != "tempdb" ] ; then
             echo "<USER_IDS_$DB>"
              nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -d "$DB" -n -h-1  -Q  "set nocount on select name from sysusers for XML AUTO, ELEMENTS" -w 400 | tr -d '[:cntrl:]' | tr -d '[:space:]'
             echo "</USER_IDS_$DB>"
           fi
           done           
          echo "</DATABASES>"
       nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -n -r -s "," -Q "sp_helpsrvrolemember"  -w 400  | sed '2d' | \
              sed 's/.*rows.*//g' | awk '{print $1, $2}'  | sed 's/[ ]*//g' | sed 'N;$!P;$!D;$d'  | sed 's/\\/\\\\/' | csv2xml -1 -x | \
              sed 's/csv2xml/SERVER-ROLE/g' | sed 's/record/ROLE/g'       
     echo "</$INSTANCE_NAME>"
       else
         echo "<$INSTANCE_NAME>"
          echo "<STATUS>The $SERVER instance is unavailable</STATUS>"
         echo "</$INSTANCE_NAME>"      
       fi      
  fi
  echo "</SQLSERVER-INSTANCES>"

else
  echo "<MSQLServer_Directory>//$HOST$SQL_SERVER_HOMEDIR directory is not found!!!</MSQLServer_Directory>"
fi

echo "</SQLSERVER_COMPLIANCE>"
