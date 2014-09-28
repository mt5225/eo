'##########
'
' Get Local Shares on Windows
' BladeLogic
' Tim Fessenden
' July 5, 2004
'
'##
' 
' Requirements:
'     * RSCD Agents installed on targets
'     * Support for cscript on the remote server
'     * WScript 5.6 on windows targets
'
'##
'
' The BladeLogic local shares script collects information about
' each share on a Windows server. It uses the "net share" command
' to derive information about the location, caching, path, and a
' variety of other pieces of information.
'
' To execute the script from NSH:
'
'   nexec <host> cscript /nologo <path_to_script>/get_local_shares.vbs
'
'   ** where <host> is the hostname and <path_to_script> is a windows
'      style path, preferably with forward slashes (such as c:/temp).
'
'
' To use this script within Extended Objects, set the following
' attributes in the CM:
'   - Remote Execution
'   - Script: cscript /nologo <path_to_file>/get_local_shares.vbs
'   - Windows INI file grammar
'   - Associate with the Windows Operating System only
'
' NOTE: Users should specify paths with a forward slash to avoid escaping
'       issues from within the BladeLogic context.
'###########

Dim WshShell, oExec, StdOut
Set StdOut = WScript.StdOut
Set WshShell = CreateObject("WScript.Shell")

' Get all users on the system
Set oExec = WshShell.Exec("net share")

Dim oRE, oMatches, oRE2, oRE3
Set oRE = New RegExp
Set oRE2 = New RegExp
Set oRE3 = New RegExp
oRE.Global = True
oRE2.Global = True
oRE3.Global = True
oRE.IgnoreCase = True
oRE2.IgnoreCase = True
oRE3.IgnoreCase = True
oRE.Pattern = "(\s\s+)"

Dim oMatch, Line, oCommand, oExec2, Line2, oMatch2, oMatches2

While Not oExec.StdOut.AtEndOfStream
    Line = oExec.StdOut.ReadLine()
    oRE.Pattern = "^Share name|-----------|The command completed|^$"
    Set oMatches = oRE.Execute(Line)

    ' Get each individual user from output of "net share"
    If oMatches.Count = 0 Then
        oRE.Pattern = "\S+"
        Set oMatches = oRE.Execute(Line)
        
        If oMatches.Count > 0 Then
					Dim strShareName
                oCommand = "net share " & Trim(oMatches(0).Value)

                ' Write the INI header for each user
                ''''WScript.StdOut.WriteLine "[" & Trim(oMatches(0).Value) & "]"
						strShareName=Trim(oMatches(0).Value)
						WScript.StdOut.Write strShareName
                ' Execute the "net share <share>" command to capture
                ' more detailed info about each user
                Set oExec2 = WshShell.Exec(oCommand)

                ' Manipulate the output into INI format (name=value)
                While Not oExec2.StdOut.AtEndOfStream

                    Line2 = Trim(oExec2.StdOut.ReadLine())

                    oRE2.Pattern = "   +"
                    'oRE2.Pattern = "   "
						  Set oMatches2 = oRE2.Execute(Line2)
                    If oMatches2.Count > 0 Then
                        For Each oMatch2 In oMatches2
                            Dim lValue, rValue
                            lValue = Left(Line2, oMatch2.FirstIndex)
                            rValue = Replace(Right(Line2, Len(Line2) - oMatch2.Length - oMatch2.FirstIndex), ":\", ":/")
                            ''WScript.Stdout.WriteLine lValue & "=" & rValue
									WScript.Stdout.Write "," & rValue
                        Next
							Else
							   oRE3.Pattern = "^$|The command completed"
								Set oMatches3 = oRE3.Execute(Line2)
								If oMatches3.Count = 0 Then
								   ''WScript.Stdout.Write Line2 & "="
									WScript.Stdout.Write ","
								End If
                    End If
                Wend

                ' Put a space at the end of each user's section
                WScript.Stdout.WriteLine ""
        End If
    End If
Wend
