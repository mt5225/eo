HOST=$1
SERVER=$1
SQL_SERVER_USER=$2
SQL_SERVER_PASSWORD=$3

nexec "$HOST" osql -U "$SQL_SERVER_USER" -P "$SQL_SERVER_PASSWORD" -S "$SERVER" -r -h-1 -Q "sp_helplogins" | grep Administrator|sed 's/ //g'