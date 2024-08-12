#!/bin/bash

cd /var/www/hia/watchlist/ || exit 1

TCP_FILES="`find data/ -type f -name '*.tcp.nmap'|wc -l`"
UDP_FILES="`find data/ -type f -name '*.udp.nmap'|wc -l`"
TCP_PROCS="`ps axw|grep -v grep|grep 'nmap .*.tcp.oG'|wc -l`"
UDP_PROCS="`ps axw|grep -v grep|grep 'nmap .*.udp.oG'|wc -l`"

echo "Active NMAPs : TCP FILES:$TCP_FILES PROCS:$TCP_PROCS | UDP FILES:$UDP_FILES PROCS:$UDP_PROCS"
echo "hia-parse-stats Active NMAPs : TCP FILES:$TCP_FILES PROCS:$TCP_PROCS | UDP FILES:$UDP_FILES PROCS:$UDP_PROCS" >> /tmp/hialog.txt

exit
#if [ "$TCP_FILES" != "$TCP_PROCS" ]
#then
  find data/ -type f -name '*.tcp.nmap' | \
  while read F
  do
    IP="`echo \"$F\"|sed 's/data\///g'|sed 's/.tcp.nmap//g'`"
    PID="`ps axw|grep -v grep|grep \"$IP.tcp.oG\"|sed 's/ pts.*//g'`"
    if [ "$PID" == "" ]
    then
      echo "hia-parse-stats Stale file: `basename \"$F\"`" | \
      tee -a /tmp/hialog.txt
    fi
  done
#fi
#if [ "$UDP_FILES" != "$UDP_PROCS" ]
#then
  find data/ -type f -name '*.udp.nmap' | \
  while read F
  do
    IP="`echo \"$F\"|sed 's/data\///g'|sed 's/.udp.nmap//g'`"
    PID="`ps axw|grep -v grep|grep \"$IP.udp.oG\"|sed 's/ pts.*//g'`"
    if [ "$PID" == "" ]
    then
      echo "hia-parse-stats Stale file: `basename \"$F\"`" | \
      tee -a /tmp/hialog.txt
    fi
  done
#fi

#4119405 pts/8    S+     1:06 nmap -PN -T5 -v -6 fc78:6e1f:1f8c:b70a:a794:c122:078b:e5c3 -sU -r -n --host-timeout 172800s -p1-65535 -oG data/fc786e1f1f8cb70aa794c122078be5c3.udp.oG
#fc0c7da1ab4b10a99556a13867eb0561.udp.nmap
