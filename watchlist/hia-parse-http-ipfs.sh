#!/bin/bash

# hia-parse-http-ipfs.sh
# 20160916

# Sanity Check
cd /var/www/hia/watchlist/ || exit 1


touch hia-parse-http-ipfs.tried
touch hia-parse-http-ipfs.found

TESTURI="QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG/readme"
TESTEXP="Hello and Welcome to IPFS!"
# wget -q -O - -6 http://[fcfe:eab4:e49c:940f:8b29:35a4:8ea8:b01a]:80/ipfs/QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG/readme|head
#Hello and Welcome to IPFS!

(
echo "hia-parse-http-ipfs begins"

wget -q -6 -O - -U "hia-parse-http-ipfs.sh/0.01 (HIA)" \
http://hia.cjdns.ca/watchlist/hia.urllist | sort | \
while read URL
do
  #Skip if exists
  if [ "`grep -Fx \"$URL\" hia-parse-http-ipfs.tried hia-parse-http-ipfs.found`" != "" ]
  then
    continue
  fi
  IP="`echo \"$URL\"|cut -d\[ -f2|cut -d\] -f1`"
  PORT="`echo \"$URL\"|cut -d\] -f2-|cut -d: -f2-|cut -d\/ -f1`"
  if [ "$PORT" == "" ]
  then
    PORT=80
  fi
  BIP="`echo $IP|tr -d ':'`"
  if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ]
  then
    continue
  fi
  echo "$URL" >> hia-parse-http-ipfs.tried
  echo -en "GET /ipfs/$TESTURI HTTP/1.1\r\nHost: [$IP]\r\nUser-Agent: hia-parse-http-ipfs.sh (HIA)\r\nAccept: */*\r\nReferer: http://hia.cjdns.ca/\r\nConnection: close\r\n\r\n" | \
  nc6 -n -w30 --idle-timeout=10 $IP $PORT 2>>/dev/null | \
  dd bs=1M count=5 2>>/dev/null | strings | grep -q "$TESTEXP" || continue
  echo "$URL" >> hia-parse-http-ipfs.found
  echo "$URL added."
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-parse-http-ipfs $URL added." >> /tmp/hialog.txt
  fi
done

echo "hia-parse-http-ipfs complete"
) 2>&1 | tee -a hia-parse-http-ipfs.log

# EOF #
