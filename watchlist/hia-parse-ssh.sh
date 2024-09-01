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
  if [ "`grep -F \"$IP\" hia.iplist`" == "" ]
  then
    continue
  fi
  if [ "`cat hia-parse-ssh.tried|grep \"^$IP $PORT$\"`" != "" ]
  then
    continue
  fi
  if [ "`cat hia-parse-ssh.found|grep \"^$IP $PORT \"`" != "" ]
  then
    continue
  fi
#  if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ] \
#  && [ "`do_ping $IP`" == "" ]
#  then
#    continue
#  fi
  echo "$IP $PORT" >> hia-parse-ssh.tried
  touch hia-parse-ssh.tmp
  nc -nv -w15 $IP $PORT 2>&1 | strings > hia-parse-ssh.tmp
  if [ "`cat hia-parse-ssh.tmp | grep 'succeeded'`" == "" ]
  then
   rm hia-parse-ssh.tmp
   continue
  fi
  if [ "`cat hia-parse-ssh.tmp | grep -v 'Connection to'`" == "" ]
  then
   rm hia-parse-ssh.tmp
   continue
  fi
  echo "-Testing IP:$IP PORT:$PORT"
  echo "$IP $PORT VERSION: `cat hia-parse-ssh.tmp | grep -v '^$' | grep -v 'Connection to' | tr '\n' '|' | sed 's/|$//g'`" >>hia-parse-ssh.found
  echo "VERSION: `cat hia-parse-ssh.tmp | grep -v '^$' | grep -v 'Connection to' | tr '\n' '|' | sed 's/|$//g'`"
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-parse-ssh $IP $PORT VERSION: `cat hia-parse-ssh.tmp | grep -v '^$' | grep -v 'Connection to' | tr '\n' '|' | sed 's/|$//g'`" \
    >> /tmp/hialog.txt
  fi
  nmap -sT -PN -6 --allports -n -p$PORT $IP --script=+ssh-hostkey &>hia-parse-ssh.tmp
  if [ "`cat hia-parse-ssh.tmp|grep 'ERROR'`" != "" ]
  then
    echo "-ERROR"
    rm hia-parse-ssh.tmp
    continue
  fi
  if [ "`cat hia-parse-ssh.tmp|grep '^|'|grep ssh-hostkey`" == "" ]
  then
    echo "-FAIL (no ssh-hostkey)"
    cat hia-parse-ssh.tmp
    rm hia-parse-ssh.tmp
    continue
  fi
  cat hia-parse-ssh.tmp | grep -v 'ssh-hostkey\|Invalid SSH identification' | grep '^|' | cut -b 5- | \
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
