
USER=$1
PASS=$2








DB_LIST=`osql -S localhost -U $USER -P $PASS -r -h-1 -s "," -Q "set nocount on select name from sysdatabases" -w 300 | tr -d '[:cntrl:]'`


echo "<DATABASES>"

for DB in $DB_LIST 
do
echo "<$DB>"

echo "<TABLES>"
TABLES=`osql -S localhost -U $USER -P $PASS -d $DB -r -h-1 -s "," -Q "set nocount on select name from sysobjects where type = 'U' " | tr -d '[:cntrl:]' `
for TABLE in $TABLES
do
  echo "<$TABLE></$TABLE>"
done
echo "</TABLES>"

echo "<TEST>"

echo '<MULTI  x="y" z="a" r="s">'

echo "</MULTI>"

echo "</TEST>"


echo "<INDEXES>"

osql -S localhost -U $USER -P $PASS -n -r -h-1 -s "," -Q "$INDEX_FILE" -w 700
echo "</INDEXES>"


#osql -S localhost -U $USER -P $PASS -n -r -h-1 -s "," -i C:\\SCRIPTS\\List_Sched.sql -w 700

echo "<CONNECTIONS>"
osql -S localhost -U $USER -P $PASS -r -h-1 -n -s "," -Q sp_who2 | grep -v 'rows affected'

echo "</CONNECTIONS>"

#osql -S localhost -U $USER -P $PASS -n -r -h-1 -s "," -i C:\\SCRIPTS\\View_All_Info.sql -w 700


echo "</$DB>"
done

echo "</DATABASES>"


