su - oracle -c "export ORACLE_SID=bsadb;sqlplus \"/as sysdba\" @/tmp/resource"
su - oracle -c "export ORACLE_SID=bsbdb;sqlplus \"/as sysdba\" @/tmp/resource"
su - oracle -c "export ORACLE_SID=bscdb;sqlplus \"/as sysdba\" @/tmp/resource"