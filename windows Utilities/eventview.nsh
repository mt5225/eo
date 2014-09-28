TARGET=$1
nexec -i $TARGET "C:\\Utilities\\eventview.bat" | grep -v LogParser
