#!/bin/bash

cd /var/www/hia/walk/ || exit 1

(
TS=`date -u +%Y%m`
touch walk.version
touch walk.peers.$TS
touch walk.pubkey
echo -n "$TS ver-m"
echo -n " .peers:`cat walk.peers.$TS|tr ' ' '\n'|sort|uniq|wc -l`"
echo -n > ver-m.walk.pubkey
cat walk.pubkey | tr ' ' '\n' | sort | uniq | \
while read L
do
  K="`echo $L|cut -d\  -f1`"
  IP="`echo $L|cut -d\  -f2`"
  if [ "`grep $IP walk.peers.$TS`" != "" ]
  then
    echo "$K $IP" >> ver-m.walk.pubkey
  fi
done
echo -n " .pubkey:$((`cat ver-m.walk.pubkey|wc -l`))"
rm ver-m.walk.pubkey
# vers this month
echo -n > ver-m.walk.version
cat walk.peers.$TS | tr ' ' '\n' | sort | uniq | \
while read IP
do
  K="`cat walk.pubkey|grep $IP$|cut -d\  -f1`"
  V="`cat walk.version|grep $K$`"
  echo "$V" >> ver-m.walk.version
done
# count num of each ver
echo -n " .version:"
cat ver-m.walk.version | cut -d\. -f1 | sort | uniq | \
while read V
do
  C=$((`cat ver-m.walk.version | cut -d\. -f1 | grep "$V" | wc -l`))
  echo -n "`echo $V|sed 's/^v//g'`:$C "
done
T=$((`cat ver-m.walk.version | cut -d\. -f1 | wc -l`))
echo "TL:$T"
rm ver-m.walk.version
) > ver-m.tmp
cat ver-m.tmp
echo "#cjdns `cat ver-m.tmp`" >> /tmp/readlog.txt
echo "#hyperboria `cat ver-m.tmp`" >> /tmp/hialog.txt
rm ver-m.tmp

# EOF #
