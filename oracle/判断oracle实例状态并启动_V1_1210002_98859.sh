ps -ef|grep smon|awk '{print $8}'|grep 'ora' > smon
a1=`grep 'bsc' smon`
a2=`grep 'bsb' smon`
a3=`grep 'bsa' smon`

if [ "$a1" = "ora_smon_bscdb" ];then
echo "oracle instance bscdb ok"
else
su - oracle -c "export ORACLE_SID=bscdb;sqlplus \"/as sysdba\" @/tmp/start.sql" 
fi

if [ "$a2" = "ora_smon_bsbdb" ];then
echo "oracle instance bsbdb ok"
else
su - oracle -c "export ORACLE_SID=bsbdb;sqlplus \"/as sysdba\" @/tmp/start.sql" 
fi

if [ "$a3" = "ora_smon_bsadb" ];then
echo "oracle instance bsadb ok"
else
su - oracle -c "export ORACLE_SID=bsadb;sqlplus \"/as sysdba\" @/tmp/start.sql" 
fi