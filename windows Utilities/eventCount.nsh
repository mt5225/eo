TARGET=$1
nexec -i $TARGET "C:\\Utilities\\eventcount.bat" | grep -v LogParser

