"C:\Utilities\LogParser.exe" -i:EVT -o:CSV -iw:ON -e:-1 -headers:OFF -q:ON "SELECT EVentLog, TimeGenerated, SourceName, Message FROM Application,Security,System WHERE EventTypeName='Error event' "
