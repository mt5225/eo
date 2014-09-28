HOST=$1
nexec "$HOST" osql -U "sa" -P "password" -S "localhost" -n -r -s "," -Q "sp_configure" -w 400 | sed '2d' | sed 's/[ ]*,/,/g'