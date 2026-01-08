#!/bin/bash

while :; do
  cd /var/www/cjdns/hia/watchlist/ || exit 1
  if [ ! -x l.sh ]; then break; fi
  ./hia-iplist.sh
  ./hia-scan-tcp.sh
  ./hia-scan-udp.sh
  ./hia-parse.sh
  ./pubk.sh
  ( cd /var/www/cjdns/hia/api/ && ./api-update.sh )
  ./clean.sh
  if [ ! -x l.sh ]; then break; fi
#  echo "-Sleeping..."
#  sleep $((60*10)) || break
  echo
done

while :
do
  echo -n > l.tmp
  ls data/*.nmap | cut -d\/ -f2 | cut -d\. -f1 | \
  while read X
  do
    ps axw|grep -v grep|grep nmap|grep $X | tee -a l.tmp
  done
  R=$((`cat l.tmp|wc -l`))
  rm l.tmp
  if [ $R -eq 0 ]
  then
    break
  fi
  echo "-Waiting for $R nmaps"
  sleep 300
done


# EOF #
