#!/bin/bash

echo "-Sorting by most peered first"
echo -n > top.iplist
echo -n > top.iplist.num
F="walk.peers.`date -u +%Y%m%d`"
cat $F | tr ' ' '\n' | sort | uniq | \
while read IP
do
  C=$((`cat $F|cut -d\  -f1|grep ^$IP|wc -l`))
  echo "$C $IP"
  echo "$C $IP" >> top.iplist.num
done | \
sort -rn | cut -d\  -f2 > top.iplist
cat top.iplist.num | sort -rn > top.iplist.num.tmp && \
mv top.iplist.num.tmp top.iplist.num
(
echo "# Most peered nodes ($((`cat $F | tr ' ' '\n' | sort | uniq | wc -l`)) nodes from $F)" 
head -n10 top.iplist.num
) | tee top.txt
