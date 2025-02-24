#!/bin/bash

touch walk.version
echo "-Counting versions"
echo -n > v.txt.new
touch v.txt
TS="`date -u +%Y%m%d`"
(
echo -n "`date -u +%Y%m%d-%H%M%S` "
touch v.walk.version
cat walk.peers.$TS | tr ' ' '\n' | sort | uniq | \
while read IP
do
  K="`cat walk.pubkey|grep $IP$|cut -d\  -f1|head -n1`"
  V="`cat walk.version|grep $K$`"
  echo "$V" >> v.walk.version
done
cat v.walk.version | cut -d\. -f1 | sort | uniq | \
while read V
do
  C=$((`cat v.walk.version | cut -d\. -f1 | grep "$V" | wc -l`))
  echo -n "$V:$C "
done
T=$((`cat v.walk.version | cut -d\. -f1 | wc -l`))
echo "TL:$T"
) 2>&1 | tee -a v.txt.new
rm v.walk.version
NV="`cat v.txt.new|cut -d\  -f2-`"
if [ "`cat v.txt|cut -d\  -f2-|grep -x \"$NV\"`" == "" ]
then
  cat v.txt.new >> v.txt
  echo "-Saved"
else
  echo "-Dupe"
fi
rm v.txt.new


# EOF #
