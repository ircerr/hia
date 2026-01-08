#!/bin/bash

cd /var/www/cjdns/hia/watchlist/walk/
(
TS=`date -u +%Y%m%d`
touch walk.version
touch walk.peers.$TS
touch walk.pubkey
echo -n "$TS ver-d"
echo -n " .peers:`cat walk.peers.$TS|tr ' ' '\n'|sort|uniq|wc -l`"
echo -n > ver-d.walk.pubkey
cat walk.pubkey | tr ' ' '\n' | sort | uniq | \
while read L
do
  K="`echo $L|cut -d\  -f1`"
  IP="`echo $L|cut -d\  -f2`"
  if [ "`grep $IP walk.peers.$TS`" != "" ]
  then
    echo "$K $IP" >> ver-d.walk.pubkey
  fi
done
echo -n " .pubkey:$((`cat ver-d.walk.pubkey|wc -l`))"
rm ver-d.walk.pubkey
# vers this month
echo -n > ver-d.walk.version
cat walk.peers.$TS | tr ' ' '\n' | sort | uniq | \
while read IP
do
  K="`cat walk.pubkey|grep $IP$|cut -d\  -f1`"
  V="`cat walk.version|grep $K$`"
  echo "$V" >> ver-d.walk.version
done
# count num of each ver
echo -n " .version:"
cat ver-d.walk.version | cut -d\. -f1 | sort | uniq | \
while read V
do
  C=$((`cat ver-d.walk.version | cut -d\. -f1 | grep "$V" | wc -l`))
  echo -n "`echo $V|sed 's/^v//g'`:$C "
done
T=$((`cat ver-d.walk.version | cut -d\. -f1 | wc -l`))
echo "TL:$T"
rm ver-d.walk.version
) > ver-d.tmp
cat ver-d.tmp
echo "#cjdns `cat ver-d.tmp`" >> /tmp/readlog.txt
echo "#hyperboria `cat ver-d.tmp`" >> /tmp/hialog.txt
rm ver-d.tmp

# EOF #
