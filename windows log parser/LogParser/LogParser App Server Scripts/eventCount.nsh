TARGET=$1
nexec -i $TARGET "C:\\Program Files\\BladeLogic\\RSC\\eventcount.bat" | grep -v LogParser

