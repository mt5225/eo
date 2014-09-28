#!/bin/nsh
#
# Copyright (C) 2006 BladeLogic, Inc.
#
# script:  sqlserver_schema_info.nsh 
#
# Description: Displays Sql Server 2000 Schema Information,
#              including Tables, Indexes, and Stored Procedures.
#              Copies the sql script to the server, nexec's the script,
#	       and removes when done.  You need to set the
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

# Copy the sql script to the server, and execute for each db in the system

sed -n '/^# set nocount/,/# for XML/p' "$0" | sed 's/# //' > //${HOST}/$$.sql

DB_LIST=`nexec $HOST osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $HOST -r -h-1 -Q "set nocount on select name from sysdatabases" -w 300 | tr -d '[:cntrl:]'`
 

echo "<SQLSERVER-SCHEMA>"
 echo "<TABLES>" 
  for DB in $DB_LIST 
  do
	 if [[ "$DB" != "master" ]]; then
	
		echo "<$DB>"
			nexec $HOST osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $HOST -d $DB -r -h-1 -Q "set nocount on select * from ${DB}.INFORMATION_SCHEMA.TABLES for XML AUTO, ELEMENTS" | tr -d '[:cntrl:]' | tr -d '[:space:]' | sed 's/[a-zA-Z]*.INFORMATION_SCHEMA.TABLES/Table/g'
		echo "</$DB>"
		
	 fi
  done
 echo "</TABLES>"
 
 
 
 
 echo "<STORED-PROCEDURES>" 
  for DB in $DB_LIST 
  do
	if [[ "$DB" != "master" ]]; then
	
		echo "<$DB>"
			nexec $HOST osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $HOST -d $DB -r -h-1 -Q "set nocount on select * from ${DB}.INFORMATION_SCHEMA.ROUTINES for XML AUTO, ELEMENTS" | tr -d '[:cntrl:]' | tr -d '[:space:]' | sed 's/[a-zA-Z]*.INFORMATION_SCHEMA.ROUTINES/Procedure/g'
		echo "</$DB>"
		
    fi
  done
 echo "</STORED-PROCEDURES>"
 
 
 
 echo "<INDEXES>"
  for DB in $DB_LIST 
  do
	if [[ "$DB" != "master" ]]; then

	echo "<$DB>"
		nexec $HOST osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $HOST -d $DB -n -r -h-1 -s "," -i $$.sql -w 700  | tr -d '[:cntrl:]' | tr -d '[:space:]' | \
							sed s'/[\<\/]*[oc]\>//g' | sed 's/\<i\>/\<Index>/g' | sed 's/\<\/i\>/\<\/Index>/g' | \
								sed 's/\<k\>/\<Key>/g' | sed 's/\<\/k\>/\<\/Key>/g'   
	echo "</$DB>"

	fi
  done
 

 echo "</INDEXES>"
  
 
echo "</SQLSERVER-SCHEMA>"

# Remove the sql script once the resultset has been returned
 
rm -f //${HOST}/$$.sql 
 
# set nocount on 
# 
# select 	o.name as 'TableName',
# 	i.name as 'IndexName',
# 	CASE WHEN (i.status & 0x800)     = 0 THEN 0 ELSE 1 END AS 'Primary', 
# 	CASE WHEN (i.status & 0x10)      = 0 THEN 0 ELSE 1 END AS 'Clustered', 
# 	CASE WHEN (i.status & 0x2)       = 0 THEN 0 ELSE 1 END AS 'Unique', 
# 	CASE WHEN (i.status & 0x1)       = 0 THEN 0 ELSE 1 END AS 'IgnoreDupKey', 
# 	CASE WHEN (i.status & 0x4)       = 0 THEN 0 ELSE 1 END AS 'IgnoreDupRow', 
# 	CASE WHEN (i.status & 0x1000000) = 0 THEN 0 ELSE 1 END AS 'NoRecompute', 
# 	i.OrigFillFactor AS 'FillFactor', 
# 	i.rowcnt as 'EsType.RowCount',
# 	i.reserved * cast(8 as bigint) as ReservedKB,  
# 	i.used * cast(8 as bigint) as UsedKB,  
# 	k.keyno as 'KeyNumber',
# 	c.name as 'ColumnName',
# --	t.name as 'DataType', 
# 	c.xprec as 'Precision',
# 	c.xscale as 'Scale', 
# 	c.iscomputed as 'IsComputed', 
# 	c.isnullable as 'IsNullable', 
# 	c.collation as 'Collation'
# from 	           sysobjects   o with(nolock)
# 	inner join sysindexes   i with(nolock) on o.id    =  i.id
# 	inner join sysindexkeys k with(nolock) on i.id    =  k.id    and    i.indid =  k.indid
# 	inner join syscolumns   c with(nolock) on k.id    =  c.id    and    k.colid =  c.colid 
# 	inner join systypes     t with(nolock) on c.xtype =  t.xtype
# 	
# where 	o.xtype <> 'S' -- Ignore system objects
# and 	i.name not like '_wa_sys_%'-- Ignore statistics 
# 
# order by
# 	o.name, 
# 	k.indid,
# 	k.keyno
# 	
# for XML Auto,ELEMENTS  
