"C:\Program Files\BladeLogic\RSC\LogParser.exe" -i:EVT -o:CSV -q:ON -iw:ON -e:-1 -headers:OFF "SELECT SourceName, COUNT(*) AS Count FROM Application,Security,System WHERE EventTypeName='Error event' GROUP BY SourceName"
