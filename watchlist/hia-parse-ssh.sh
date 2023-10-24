#!/bin/bash

# hia-parse-ssh.sh
# 20160517

# Read hia-parse-vers.found for SSH IP PORT list
# Save SSH HostKeys to hia-parse-ssh.found as IP PORT HOSTKEY
# Perhaps compare to detect conf regen and non unique hostkeys
# Perhaps compare to detect changed hostkeys

do_ping () {
  IP=$1
  /home/cjdns/cjdns/tools/cexec "RouterModule_pingNode(\"$IP\")" 2>&1 | \
  grep '"result": "pong"' && echo "[api] $IP UP" 1>&2
  #|| echo "[api] $IP DOWN" 1>&2
}

# Sanity check
cd /var/www/hia/watchlist/ || exit 1

(

echo -n > hia-parse-ssh.tried
touch hia-parse-ssh.found
echo "hia-parse-ssh begins"
cat hia-parse-ver.found | grep -i ssh | cut -d\  -f-2 | sort | uniq | \
while read IP PORT
do
  if [ "`cat hia-parse-ssh.tried|grep -x \"$IP $PORT\"`" != "" ]
  then
    continue
  fi
  if [ "`cat hia-parse-ssh.found|grep \"^$IP $PORT \"`" != "" ]
  then
    continue
  fi
  if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ] \
  && [ "`do_ping $IP`" == "" ]
  then
    continue
  fi
  nc -nvz -w15 $IP $PORT 2>&1 | grep -q 'succeeded' || continue
  echo "$IP $PORT" >> hia-parse-ssh.tried
  echo "IP:$IP PORT:$PORT"
  nmap -sT -PN -6 -n -p$PORT $IP --script=+ssh-hostkey &>hia-parse-ssh.tmp
  if [ "`cat hia-parse-ssh.tmp|grep '^|'|grep ssh-hostkey`" == "" ]
  then
    echo "-FAIL"
    cat hia-parse-ssh.tmp
    rm hia-parse-ssh.tmp
    continue
  fi
#|_ssh-hostkey: 2048 9b:7b:10:09:7b:ca:5a:c0:c7:65:f4:ae:f1:a4:36:1a (RSA)
  cat hia-parse-ssh.tmp | grep '^|' | sed 's/^| ssh-hostkey: /|_/g' | \
  sed 's/^|_ssh-hostkey: /|_/g' | sed 's/^|_//g' | \
  while read KEY
  do
    echo "-Found: $KEY"
    echo "$IP $PORT $KEY" >> hia-parse-ssh.found
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-ssh $IP $PORT $KEY" >> /tmp/hialog.txt
    fi
  done
  rm hia-parse-ssh.tmp
done
echo "hia-parse-ssh complete"
) 2>&1 | tee -a hia-parse-ssh.log

exit

# EOF #
