#!/bin/bash

# hia-parse-ssl.sh
# 20161517

# Read hia-parse-vers.found for ssl IP PORT list
# Save ssl cert info to hia-parse-ssl.found as IP PORT DATA
# Perhaps compare to detect conf regen and non unique keys
# Perhaps compare to detect changed keys

# To check: https://crt.sh/?q=mail.rxv.cc

do_ping () {
  IP=$1
  /home/cjdns/cjdns/tools/cexec "RouterModule_pingNode(\"$IP\")" 2>&1 | \
  grep '"result": "pong"' && echo "[api] $IP UP" 1>&2
  #|| echo "[api] $IP DOWN" 1>&2
}

# Sanity check
cd /var/www/hia/watchlist/ || exit 1

(

echo -n > hia-parse-ssl.tried
touch hia-parse-ssl.found
echo "hia-parse-ssl begins"
cat hia-parse-ver.found | grep ' ssl|' | cut -d\  -f-2 | sort | uniq | \
while read IP PORT
do
  if [ "`grep -F \"$IP\" hia.iplist`" == "" ]
  then
    continue
  fi
  if [ "`cat hia-parse-ssl.tried|grep -x \"$IP $PORT\"`" != "" ]
  then
    continue
  fi
  if [ "`cat hia-parse-ssl.found|grep \"^$IP $PORT \"`" != "" ]
  then
    continue
  fi
  if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ] \
  && [ "`do_ping $IP`" == "" ]
  then
    continue
  fi
  nc -nvz -w15 $IP $PORT 2>&1 | grep -q 'succeeded' || continue
  echo "$IP $PORT" >> hia-parse-ssl.tried
  echo "IP:$IP PORT:$PORT"
  nmap -sT -PN -6 -n -p$PORT $IP --script=+ssl-cert &>hia-parse-ssl.tmp
#| ssl-cert: Subject: commonName=*.tuxli.ch
#| MD5:   c9f9 9ac7 90c7 b6c2 f472 70ba 4930 cb9a
#|_SHA-1: 1105 8a21 fa1f c1c9 665e 5a0b ced0 8ae1 f218 04ec
  if [ "`cat hia-parse-ssl.tmp|grep '^|'|grep ssl-cert`" == "" ]
  then
    echo "-FAIL"
    cat hia-parse-ssl.tmp
    rm hia-parse-ssl.tmp
    continue
  fi
  cat hia-parse-ssl.tmp | grep '^|' | \
  sed 's/^| ssl-cert: //g' | sed 's/^|_//g' | sed 's/^| //g' | \
  while read DATA
  do
    echo "-Found: $DATA"
    echo "$IP $PORT $DATA" >> hia-parse-ssl.found
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-ssl [$IP] $PORT $DATA" >> /tmp/hialog.txt
    fi
  done
  rm hia-parse-ssl.tmp
done
echo "hia-parse-ssl complete"
) 2>&1 | tee -a hia-parse-ssl.log

exit

# EOF #
