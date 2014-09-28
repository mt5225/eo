TARGET=$1
nexec -i $TARGET "C:\\Program Files\\BladeLogic\\RSC\\eventview.bat" | grep -v LogParser
