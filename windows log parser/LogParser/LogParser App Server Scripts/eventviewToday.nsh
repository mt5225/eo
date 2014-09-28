TARGET=$1
TD=`date +%Y-%m-%d`
echo $TD
nexec -i $TARGET "C:\\eventview.bat" | grep -v LogParser | grep $TD
exit 0