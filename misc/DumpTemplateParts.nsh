#!/bin/nsh
 
authProfile="${1}"
roleName="${2}"
templateGroup="${3}"
templateName="${4}"
 
outputFile="${templateName}.`date +%Y%m%d%H%M%S`.csv"
 
blcli_setoption serviceProfileName "${authProfile}"
blcli_setoption roleName "${roleName}"
blcli_connect
 
blcli_execute Template getDBKeyByGroupAndName "${templateGroup}" "${templateName}"
blcli_execute Template getParts
blcli_execute Utility setTargetObject
blcli_execute Utility storeTargetObject templateParts
blcli_execute TemplatePart getEscapedPath
blcli_execute Utility setTargetObject
blcli_execute Utility listPrint
blcli_storeenv partsPath
blcli_execute Utility setTargetObject templateParts
blcli_execute TemplatePart getAllowedOperations
blcli_execute Utility setTargetObject
blcli_execute Utility listPrint
blcli_storeenv partOps
 
echo "${partsPath}" | while read partPath
do
 
	parts=("${partPath}" "${parts[@]}")
done
 
 
echo "${partOps}" | while read partOp
do
 
	partOp="`echo ${partOp} | sed "s/\[//g;s/\]//g" | tr -d '[:space:]'`"
	OLDIFS="${IFS}"
	IFS=,
	for op in ${partOp}
		do		
		[ "${op}" = "Audit" ] && a="true" || a="false"
		[ "${op}" = "Discover" ] && d="true" || d="false"
		[ "${op}" = "Browse" ] && b="true" || b="false"
		[ "${op}" = "Snapshot" ] && s="true" || s="false"
		[ "${op}" = "Compliance" ] && c="true" || c="false"
	done
	IFS=${OLDIFS}
	partOp="${d}\",\"${b}\",\"${s}\",\"${a}\",\"${c}\""
 
	ops=("${partOp}" "${ops[@]}")
 
done
 
echo "\"Part\",\"Discover\",\"Browse\",\"Snapshot\",\"Audit\",\"Compliance\"" >> "${outputFile}"
count=1
 
while [ ${count} -le ${#parts} ]
do
        if [ "${parts[${count}]}x" != "x" ]
                then
                echo "\"${parts[${count}]}\",\"${ops[${count}]}" >> "${outputFile}"
        fi
                count=$((${count}+1))
done