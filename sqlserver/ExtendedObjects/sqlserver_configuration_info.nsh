#!/bin/nsh
#
# Copyright (C) 2006 BladeLogic, Inc.
#
# script:  sqlserver_configuration_info.nsh 
#
# Description: This script displays Sql Server 2000 Configuration
#              Information.
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
#
########################################################################             
#
# Init variables
#
#########################################################################

HOST=$1
SQL_SERVER_USER=$2
SQL_SERVER_PASSWORD=$3

# Copy the sql server script, and execute

sed -n '/^# Set Nocount On/,/# Set Nocount Off/p' "$0" | sed 's/# //' > //${HOST}/$$.sql

echo "<DATAFILES>"

	nexec $HOST osql -U $SQL_SERVER_USER -P $SQL_SERVER_PASSWORD -S $HOST -n -r -h-1 -i $$.sql -w 700 | tr -d '[:cntrl:]' | tr -d '[:space:]' | sed 's/_x0023__x0023_helpfile/DATAFILE/g'
 
echo "</DATAFILES>"

# Remove the sql script once the resultset has returned

rm -f //${HOST}/$$.sql

# Set Nocount On
# 
# 
# Create Table ##helpfile (
# 	ObsvDate datetime NULL,
# 	ServerName varchar(50) NULL,
# 	DbName varchar(100) NULL, 
# 	FileLogicalName varchar(100) NULL, 
# 	FileID int NULL,
# 	FileGroupID int NULL, 
# 	FilePath varchar(100) NULL, 
# 	FileGroupName varchar(50) NULL, 
# 	FileTotalSizeKB varchar(20) NULL, 
# 	FileMaxSizeSetting varchar(20) NULL, 
# 	FileGrowthSetting varchar(20) NULL, 
# 	FileUsage varchar(20) NULL,
# 	FileTotalSizeMB dec(19,4) NULL, 
# 	FileUsedSpaceMB dec(19,4) NULL, 
# 	FileFreeSpaceMB dec(19,4) NULL, 
# 	)
# 
#  Create Table ##filestats (
# 	DbName varchar(100) NULL, 
# 	FileID int NULL, 
# 	FileGroupID int NULL, 
# 	FileTotalSizeMB  dec(19,4) NULL, 
# 	FileUsedSpaceMB  dec(19,4) NULL, 
# 	FileFreeSpaceMB  dec(19,4) NULL, 
# 	FileLogicalName varchar(100) NULL, 
# 	FilePath varchar(100) NULL
# 	)
# 
#  Create Table ##sqlperf (
# 	DbName varchar(100) NULL,
# 	LogFileSizeMB dec(19,4) NULL,
# 	LogFileSpaceUsedpct dec(19,4) NULL,
# 	Status int NULL
# 	)
# 
#  Insert ##sqlperf (DbName, LogFileSizeMB, LogFileSpaceUsedpct, Status) Exec ( 'DBCC SQLPERF ( LOGSPACE ) WITH NO_INFOMSGS ')
# 
#  Exec sp_MSForeachDB 	
#  --@command1 = 'Use ?; DBCC UPDATEUSAGE(0)',
#  @command1 = 'Use ?;Insert ##helpfile (FileLogicalName, FileID, FilePath, FileGroupName, FileTotalSizeKB, FileMaxSizeSetting, FileGrowthSetting,FileUsage) Exec sp_helpfile; update ##helpfile set dbname = ''?'' where dbname is null', 
#  @command2 = 'Use ?;Insert  ##filestats (FileID, FileGroupID, FileTotalSizeMB, FileUsedSpaceMB, FileLogicalName, FilePath) exec (''DBCC SHOWFILESTATS WITH NO_INFOMSGS ''); update ##filestats set dbname = ''?'' where dbname is null'
# 
#  -- remove any db's that we don't care about monitoring
#  Delete From ##filestats where charindex(dbname, 'master-model-pubs-northwind-distribution-msdb') > 0
#  Delete from ##helpfile where  charindex(dbname, 'master-model-pubs-northwind-distribution-msdb') > 0
#  Delete from ##sqlperf where  charindex(dbname, 'master-model-pubs-northwind-distribution-msdb') > 0
# 
#  Update ##filestats set FileTotalSizeMB = Round(FileTotalSizeMB*64/1024,2), FileUsedSpaceMB = Round(FileUsedSpaceMB*64/1024,2) 
#  where FileFreeSpaceMB is null
# 
#  Update ##filestats set FileFreeSpaceMB = FileTotalSizeMB - FileUsedSpaceMB 
#  where FileFreeSpaceMB is null
# 
#  Update ##helpfile set FileGroupID = 0 Where FileUsage = 'log only'
# 
#  Update ##helpfile set FileGroupID = b.FileGroupID,  FileTotalSizeMB = b.FileTotalSizeMB, FileUsedSpaceMB = b.FileUsedSpaceMB, FileFreeSpaceMB = b.FileFreeSpaceMB  
#  From ##helpfile a, ##filestats b
# 
#  Where a.FilePath = b.FilePath and a.FileUsage = 'data only'
# 
#  Update ##helpfile set FileTotalSizeMB = Round(Cast(replace(FileTotalSizeKB,' KB', '')as dec(19,4))/1024,2) 
#  where FileTotalSizeMB is NULL
# 
#  Update ##helpfile set FileUsedSpaceMB = Round(FileTotalSizeMB * b.LogFileSpaceUsedpct * 0.01, 2), FileFreeSpaceMB = Round(FileTotalSizeMB * (100 - b.LogFileSpaceUsedpct) * 0.01, 2)  
#  From ##helpfile a, ##sqlperf b
#  Where a.dbname = b.dbname and a.FileUsage = 'log only'
# 
#  DECLARE @obsvdate datetime
#  Set @obsvdate = getdate()
# 
#  Update ##helpfile set ObsvDate = @obsvdate where ObsvDate is null
# 
# 
#  -- 97 : 122 = a to z
#  -- 65 : 90  = A to Z
#  Update ##helpfile Set FilePath = STUFF ( FilePath , 1 , 1 , Upper(Left(FilePath,1)) ) Where Unicode(Left(FilePath,1)) between 97 and 122
# 
#  Update ##helpfile set servername = @@servername Where ServerName Is Null
# 
#  Select ObsvDate,ServerName, DbName,FileLogicalName,FileID,FilePath,FileGroupID, FileGroupName, FileTotalSizeKB, FileTotalSizeMB, FileUsedSpaceMB,FileFreeSpaceMB, FileMaxSizeSetting, FileGrowthSetting,FileUsage from ##helpfile FOR XML AUTO, ELEMENTS
# 
#  Drop table ##helpfile
#  Drop table ##filestats
#  Drop table ##sqlperf
#  
#  
# Set Nocount Off
