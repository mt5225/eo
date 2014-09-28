su - oracle -c "export ORACLE_SID=bsadb;sqlplus \"/as sysdba\" @/tmp/tempfile"
su - oracle -c "export ORACLE_SID=bsbdb;sqlplus \"/as sysdba\" @/tmp/tempfile"
su - oracle -c "export ORACLE_SID=bscdb;sqlplus \"/as sysdba\" @/tmp/tempfile"