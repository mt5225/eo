a=`su - oracle -c "export ORACLE_SID=bsadb;sqlplus \"/as sysdba\" @/tmp/object"`
echo $a