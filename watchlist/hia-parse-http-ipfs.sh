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
  if [ "`grep -x \"$URL\" hia-parse-http-ipfs.tried hia-parse-http-ipfs.found`" != "" ]
  then
    continue
  fi
  IP="`echo \"$URL\"|cut -d\[ -f2|cut -d\] -f1`"
  BIP="`echo $IP|tr -d ':'`"
  if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ]
  then
    continue
  fi
  echo "$URL" >> hia-parse-http-ipfs.tried
  wget -q -6 -O - -T5 -t1 -U "hia-parse-http-ipfs.sh/0.01 (HIA)" \
  "${URL}ipfs/$TESTURI" | strings | grep -q "$TESTEXP" || continue
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
