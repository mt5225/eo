HOST=$1
fs=`ndf $HOST -H | sed 's/\%//g' | awk '{print $2}'`
for line in ${fs}
do
  out=`grep ${line} //$HOST/etc/fstab`
  if [ -n "${out}" ]; then 
    echo "${line} EXIST"
  else
    echo "${line} MISSING"
  fi
done