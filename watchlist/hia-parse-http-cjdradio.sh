#!/bin/bash

# cjdradio Detector

touch hia-parse-http-cjdradio.found

cat hia.portlist | grep ':55227 ' | \
while read LINE
do
#[fc74:68c3:8225:bb21:b981:9826:ca32:723c]:55227 TCP
  IP="`echo \"$LINE\"|cut -d\[ -f2|cut -d\] -f1`"
  grep -q "$IP" hia.iplist || continue
  grep -q "$IP" hia-parse-http-cjdradio.found && continue
  ID="`curl -s http://[$IP]:55227/id`"
  if [ "$ID" != "" ]
  then
    echo "$IP $ID" | tee -a hia-parse-http-cjdradio.found
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-http-cjdradio $IP -> $ID added." >> /tmp/hialog.txt
    fi
  fi
done

#http://[X]:55227/listpeers
#http://[X]:55227/ping
#http://[X]:55227/random-mp3
#http://[X]:55227/mp3? ..
#http://[X]:55227/id
#http://[X]:55228/flac-size
#http://[X]:55228/flac-catalog
#http://[X]:55228/flac? ..?
#http://[X]:55228/flac-size

