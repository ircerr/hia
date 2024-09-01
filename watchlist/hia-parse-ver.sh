#!/bin/bash

# hia-parse-ver.sh
# 20140928

# Read IP:PORT from hia.portlist
# Do nmap on IP:PORT, save found to hia-parse-ver.found

do_ping () {
  IP=$1
  /home/cjdns/cjdns/tools/cexec "RouterModule_pingNode(\"$IP\")" 2>&1 | \
  grep '"result": "pong"' && echo "[api] $IP UP" 1>&2
  #|| echo "[api] $IP DOWN" 1>&2
}

cd /var/www/hia/watchlist/ || exit 1

(

touch hia-parse-ver.tried
touch hia-parse-ver.found
echo "hia-parse-ver begins"
cat hia.portlist | \
cut -d\[ -f2 | cut -d\] -f1 | \
sort -n | uniq | \
while read IP
do
  if [ "`grep -F \"$IP\" hia.iplist`" == "" ]
  then
    continue
  fi
  if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ] \
  && [ "`do_ping $IP`" == "" ]
  then
    continue
  fi
  #TCP
  cat hia.portlist | grep "$IP" | cut -d\] -f2 | cut -d: -f2 | grep TCP$ | cut -d\  -f1 | \
  while read PORT
  do
    if [ "`cat hia-parse-ver.tried|grep -x \"$IP $PORT TCP\"`" != "" ]
    then
      continue
    fi
    echo "$IP $PORT TCP" >> hia-parse-ver.tried
    if [ "`cat hia-parse-ver.found 2>>/dev/null|grep \"^$IP $PORT TCP \"`" == "" ]
    then
      echo -n "$IP $PORT TCP "
      nmap -n -6 -PN -sT --allports -p $PORT $IP -sV -oG - 2>&1 | \
      grep 'Ports:'|sed 's/.*Ports: //g' | tee hia-parse-ver.portlist.tmp \
      || echo ERR
      if [ "`cat hia-parse-ver.portlist.tmp|grep -v '^$\|/closed/\|/tcpwrapped/'`" != "" ]
      then
        S="`cat hia-parse-ver.portlist.tmp|cut -d\/ -f5`"
        V="`cat hia-parse-ver.portlist.tmp|cut -d\/ -f7`"
        if [ "$S" != "" ] \
        && [ "$V" != "" ]
        then
          echo "+ $IP $PORT TCP $S $V"
          echo "$IP $PORT TCP $S $V" >> hia-parse-ver.found
          if [ -f /tmp/hialog.txt ]
          then
            echo "hia-parse-ver [$IP]:$PORT TCP $S $V" >> /tmp/hialog.txt
          fi
        fi
      fi
      rm hia-parse-ver.portlist.tmp
    fi
  done
  #UDP
  cat hia.portlist | grep "$IP" | cut -d\] -f2 | cut -d: -f2 | grep UDP$ | cut -d\  -f1 |  \
  while read PORT
  do
    if [ "`cat hia-parse-ver.tried|grep -x \"$IP $PORT UDP\"`" != "" ]
    then
      continue
    fi
    echo "$IP $PORT UDP" >> hia-parse-ver.tried
    if [ "`cat hia-parse-ver.found 2>>/dev/null|grep \"^$IP $PORT UDP \"`" == "" ]
    then
      echo -n "$IP $PORT UDP "
      nmap -n -6 -PN -sU --allports -p $PORT $IP -sV -oG - 2>&1 | \
      grep 'Ports:'|sed 's/.*Ports: //g' | tee hia-parse-ver.portlist.tmp \
      || echo ERR
      if [ "`cat hia-parse-ver.portlist.tmp|grep -v '^$\|/closed/\|/tcpwrapped/'`" != "" ]
      then
        S="`cat hia-parse-ver.portlist.tmp|cut -d\/ -f5`"
        V="`cat hia-parse-ver.portlist.tmp|cut -d\/ -f7`"
        if [ "$S" != "" ] \
        && [ "$V" != "" ]
        then
          echo "+ $IP $PORT UDP $S $V"
          echo "$IP $PORT UDP $S $V" >> hia-parse-ver.found
          if [ -f /tmp/hialog.txt ]
          then
            echo "hia-parse-ver [$IP]:$PORT UDP $S $V" >> /tmp/hialog.txt
          fi
        fi
      fi
      rm hia-parse-ver.portlist.tmp
    fi
  done
done
echo "hia-parse-ver complete"
) 2>&1 | tee -a hia-parse-ver.log

exit

# EOF #
