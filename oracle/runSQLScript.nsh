echo "select * from dual;" > /tmp/1.sql
nexec -e su - oracle -c "ORACLE_SID=bladedb;sqlplus bladelogic/as @/tmp/1.sql"
del /tmp/1.sql