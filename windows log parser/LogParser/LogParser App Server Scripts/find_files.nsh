#! /bin/nsh
#<name> fild_files.nsh
#<desc> Search for files/directories and return the results
#<type> Sensor
#<owner> Copyright (C) 2006 BladeLogic, Inc.
#######################################################################
#<doc> NAME
#<doc>         find_files.nsh
#<doc>
#<doc> SYNTAX
#<doc>         find.nsh  servername
#<doc>
#<doc> DIAGNOSTICS
#<doc>         Exit code 0 if successful
#<doc>                   0 on failure
#<doc>
#<doc> DESCRIPTION
#<doc>         Look for all specific files
#<doc>
#######################################################################
#  MODIFY DATE   MODIFIED BY   REASON FOR & DESCRIPTION OF MODIFICATION
#  -----------  -------------  ----------------------------------------
#  08/15/06         Ben Newton  Created
#######################################################################

TARGET=$1
OUTPUT_FILE="/C/tmp/out.txt"
INPUT_FILE="/C/Program Files/Bladelogic/OM/share/sensors/blacklist.txt"

#Get the names of the files
BLACKLIST=""
sort "$INPUT_FILE" | while read FILE
do
	#echo "$FILE##"
	if [[ "$BLACKLIST" = "" ]]; then
		BLACKLIST="'$FILE'"
	else
		BLACKLIST=`echo "$BLACKLIST;'$FILE'"`
	fi
done

nexec -i $TARGET "C:\\Program Files\\BladeLogic\\RSC\\findfiles.bat" "\"$BLACKLIST\"" | grep -v LogParser | sort > /C/tmp/out.txt

cat  /C/tmp/out.txt | grep "\\\\"
rm /C/tmp/out.txt
