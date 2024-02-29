#!/bin/bash

function test_ip() {
  IP="$1"
  echo -n > hia-parse-nntp.in
  echo -n > hia-parse-nntp.out
  tail -F hia-parse-nntp.in | \
  socat - TCP6:[$IP]:119 | \
  tee hia-parse-nntp.out | \
  while read LINE
  do
    LINE="`echo \"$LINE\"|tr -d '\r'`"
#    echo "LINE:\"$LINE\""
    echo "$IP $LINE" >> hia-parse-nntp.log
    if [ "`echo \"$LINE\"|grep '^200 '`" != "" ]
    then
      echo "$LINE" | sed 's/^200 //g'
      echo "LIST" >> nntp.in
      continue
    fi
    if [ "`echo \"$LINE\"|grep '\.$'`" != "" ]
    then
      echo "QUIT" >> nntp.in
      continue
    fi
  done
  rm hia-parse-nntp.in hia-parse-nntp.out
  return
}

touch hia-parse-nntp.found

cat hia.portlist | grep ':119 TCP' | \
while read LINE
do
  IP="`echo \"$LINE\"|cut -d\[ -f2|cut -d\] -f1`"
  grep -q "$IP" hia.iplist || continue
  grep -q "$IP" hia-parse-nntp.found && continue
  ID="`test_ip \"$IP\"`"
  if [ "$ID" == "" ]
  then
    continue
  fi
  echo "$IP $ID" >> hia-parse-nntp.found
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-parse-nntp $IP -> $ID added." >> /tmp/hialog.txt
  fi
done

