#!/bin/nsh
# 
#  Copyright (C) 2007 BladeLogic, Inc.
# 
#  script:  get_local_shares.nsh 
# 
#  Description: Wrapper for $$.vbs script that retrieves Audit Failure 
# 	        in Security log.
#  
#
#   MODIFY DATE   MODIFIED BY     REASON FOR & DESCRIPTION OF MODIFICATION
#   -----------  -------------    ----------------------------------------
#   12/01/07      Andrew Knott    Copied from audit_security_log.nsh and get_local_shares.vbs
# 
#  Init variables
#
TARGEt=$1

sed -n '/^# Option Explicit/,/# End.VBScript/p' "$0" | \
sed 's/^# //' > //${TARGEt}/C/$$.vbs


nexec $TARGEt cscript /nologo "C:\\$$.vbs" > tmp.$$

 
#nexec $TARGEt cscript /nologo "C:\\$$.vbs" > tmp.$$


#Get the local permissions for each share
while read LINE
do 

if  echo $LINE | grep '^<Path>'  ; then

  FS_PATH=`echo $LINE | sed -e 's#<Path>##g' -e 's#</Path>##g' -e 's#/#\\\\#g' | tr -d '[:cntrl:]'`
#  echo '<note>in path</note>' $FS_PATH

#echo  nexec $1 cacls "$FS_PATH"
echo nothing > foo
nexec $1 cacls "$FS_PATH"   < foo |  sed -e 's/^ *//' -e 's#\\#_#g' | 
awk 'NR == 2 { print "<FS_Permissions>" ; FS=":" ; split($2, a, ":") ; print "<" a[1] ">" a[2] "</" a[1] ">"  } ; 
     NR > 2 { if ( $2 != "") { gsub(" ","_", $1 ) ; print "<" $1  ">" $2 "</" $1 ">" } } ;
     END { print "</FS_Permissions>" } ; '

rm foo 
else
 echo $LINE
fi
done < tmp.$$


#./fs_perms.nsh  $TARGEt tmp.$$

# Remove the vbs script from the server once the results 
# have been returned.
rm -f //${TARGEt}/C/$$.vbs tmp.$$

exit 0

# Option Explicit
# '##########
# '
# ' Get Local Shares on Windows
# ' BladeLogic
# ' Tim Fessenden
# ' July 5, 2004
# '
# '##
# ' 
# ' Requirements:
# '     * RSCD Agents installed on targets
# '     * Support for cscript on the remote server
# '     * WScript 5.6 on windows targets
# '
# '##
# '
# ' The BladeLogic local shares script collects information about
# ' each share on a Windows server. It uses the "net share" command
# ' to derive information about the location, caching, path, and a
# ' variety of other pieces of information.
# '
# ' To execute the script from NSH:
# '
# '   nexec <host> cscript /nologo <path_to_script>/get_local_shares.vbs
# '
# '   ** where <host> is the hostname and <path_to_script> is a windows
# '      style path, preferably with forward slashes (such as c:/temp).
# '
# '
# ' To use this script within Extended Objects, set the following
# ' attributes in the CM:
# '   - Remote Execution
# '   - Script: cscript /nologo <path_to_file>/get_local_shares.vbs
# '   - Windows INI file grammar
# '   - Associate with the Windows Operating System only
# '
# ' NOTE: Users should specify paths with a forward slash to avoid escaping
# '       issues from within the BladeLogic context.
# '###########
# 
# Dim WshShell, oExec, StdOut
# Set StdOut = WScript.StdOut
# Set WshShell = CreateObject("WScript.Shell")
# 
# ' Get all users on the system
# Set oExec = WshShell.Exec("net share")
# 
# Dim strShareName
# 
# Dim lValue2, rValue2
# Dim oRE, oMatches, oRE2, oRE3, oRE4, Permission
# Set oRE = New RegExp
# Set oRE2 = New RegExp
# Set oRE3 = New RegExp
# Set oRE4 = New RegExp
# oRE.Global = True
# oRE2.Global = True
# oRE3.Global = True
# oRE4.Global = True
# oRE.IgnoreCase = True
# oRE2.IgnoreCase = True
# oRE3.IgnoreCase = True
# oRE4.IgnoreCase = True
# oRE.Pattern = "(\s\s+)"
# 
# Dim oMatch, Line, oCommand, oExec2, Line2, oMatch2, oMatches2, oMatches3, oMatches4, oMatch4
# 
# WScript.Stdout.WriteLine "<Shares>"
# 
# While Not oExec.StdOut.AtEndOfStream
#     Line = oExec.StdOut.ReadLine()
# 
#     'Filter out non-share output
#     oRE.Pattern = "^Share name|-----------|The command completed|^$"
#     Set oMatches = oRE.Execute(Line)
# 
#     ' Get each individual user from output of "net share"
#     If oMatches.Count = 0 Then
#         oRE.Pattern = "\S+"
#         Set oMatches = oRE.Execute(Line)
#         
#         If oMatches.Count > 0 Then
#                 oCommand = "net share " & Trim(oMatches(0).Value)
# 
#                 ' Write the INI header for each user
#                 ''''WScript.StdOut.WriteLine "[" & Trim(oMatches(0).Value) & "]"
# 						strShareName=Trim(oMatches(0).Value)
# 						WScript.StdOut.WriteLine "<" & Replace(strShareName,"$","") & ">"
#                 ' Execute the "net share <share>" command to capture
#                 ' more detailed info about each user
#                 Set oExec2 = WshShell.Exec(oCommand)
# 
#                 ' Manipulate the output into INI format (name=value)
#                 While Not oExec2.StdOut.AtEndOfStream
# 
#                     Line2 = Trim(oExec2.StdOut.ReadLine())
# 
#                     oRE2.Pattern = "   +"
#                     'oRE2.Pattern = "   "
# 			  Set oMatches2 = oRE2.Execute(Line2)
#                     If oMatches2.Count > 0 Then
#                         For Each oMatch2 In oMatches2
#                             Dim lValue, rValue
#                             lValue = Replace(Left(Line2, oMatch2.FirstIndex)," ","_")
#                             rValue = Replace(Right(Line2, Len(Line2) - oMatch2.Length - oMatch2.FirstIndex), "\", "/")
#                             ''WScript.Stdout.WriteLine lValue & "=" & rValue
# 					If lValue = "Permission" Then
# 						Permission = 1
# 						WScript.Stdout.WriteLine   "<" & Replace(lValue, "/", "_") & ">"  
# 						oRE4.Pattern = ", "
# 						Set oMatches4 = oRE4.Execute(rValue)
# 			                  If oMatches4.Count > 0 Then
#                   				For Each oMatch4 In oMatches4
# '								Dim lValue2, rValue2
# 								lValue2 = Replace(Left(rValue, oMatch4.FirstIndex),"\",".")
# 								rValue2 = Right(rValue, Len(rValue) - oMatch4.Length - oMatch4.FirstIndex)
# 								WScript.Stdout.WriteLine  "<" & Replace(lValue2, "/", "_") & ">" & rValue2 & "</" & Replace(lValue2, "/", "_") & ">" 
# 							Next
# 						End If
# 			
# 					Else 
# 						WScript.Stdout.WriteLine  "<" & lValue & ">" & rValue & "</" & lValue & ">" 
# 					End If
#                         Next
# 			  Else
# 				oRE3.Pattern = "^$|The command completed"
# 				Set oMatches3 = oRE3.Execute(Line2)
# 				If oMatches3.Count = 0 And Permission = 1 Then
# 					''WScript.Stdout.Write Line2 & "="
# 					oRE4.Pattern = ", "
# 					rValue=Line2
# 					Set oMatches4 = oRE4.Execute(rValue)
# 		                  If oMatches4.Count > 0 Then
#                  				For Each oMatch4 In oMatches4
# '							Dim lValue2, rValue2
# 							lValue2 = Replace(Left(rValue, oMatch4.FirstIndex),"\",".")
# 							rValue2 = Right(Line2, Len(rValue) - oMatch4.Length - oMatch4.FirstIndex)
# 							WScript.Stdout.WriteLine  "<" & lValue2 & ">" & rValue2 & "</" & lValue2 & ">" 
# 						Next
# 					Else
# 						'WScript.Stdout.WriteLine Line2
# 					End If
# 				End If
#                     End If
#                 Wend
# 
#                 ' Put a space at the end of each user's section
# 			
# 			If Permission = 1 Then               
# 				WScript.Stdout.WriteLine "</Permission>"
# 			End If
# 			
# 			WScript.StdOut.WriteLine "</" & Replace(strShareName,"$","") & ">"
# 		      Permission = 0
#         End If
#     End If
# Wend
# 
# WScript.Stdout.WriteLine "</Shares>"
# 
# 
# 
#  'End.VBScript
