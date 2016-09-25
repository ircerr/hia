#!/bin/bash

# hia-parse-nodeinfo.sh
# 20150628

# Check results of HIA HTTP Scanner
# Test all opep HTTP ports for /nodeinfo.json
# Generate list of all found ips

# Read URLs from hia.urllist
# Do test for nodeinfo.json
# Save found to hia.nodeinfo

# Sanity check
cd /var/www/hia/watchlist/ || exit 1

touch hia.urllist
mkdir -p data/
touch hia-parse-nodeinfo.tried
touch hia.nodeinfo

#Functions
function padip() {  #Pad IP - fill in missing zeros
  ip=$1
  if [ "$ip" == "" ]; then return; fi
  PADIP=""
  SEGIP="`echo $ip|tr ':' ' '`"
  for S in $SEGIP
  do
    while :
    do
      if [ "`echo $S|cut -b 4`" == "" ]
      then
        S="0$S"
        continue
      fi
      if [ "$PADIP" == "" ]
      then
        PADIP="$S"
      else
        PADIP="$PADIP:$S"
#        echo "PADIP.:$PADIP" 1>&2
      fi
      break
    done
  done
#  echo "PADIP:$PADIP" 1>&2
  if [ "$PADIP" != "" ]
  then
    ip="$PADIP"
  fi
  echo "$ip"
  return
}


#for log
(

echo "hia-parse-nodeinfo begins"

URLSNUM=$((`cat hia.urllist|sort|uniq|wc -l`))
echo "-Checking results for $URLSNUM URLs"

#http://[fc15:491b:0549:9d8a:8480:45f8:bd10:a53e]:80/
cat hia.urllist | \
sort -n | uniq | \
while read URL
do
  #Pad IPV6 to include missing zeros
  IP="`echo $URL|cut -d\[ -f2|cut -d\] -f1`"
  IP="`padip $IP`"
  #Port
  PORT="`echo $URL|cut -d\] -f2|cut -d\/ -f1|cut -d: -f2`"
  #Remove :'s for file/dir name usage
  BIP="`echo $IP|tr -d ':'`"
  NIURL="${URL}nodeinfo.json"
  if [ "`cat hia-parse-nodeinfo.tried|grep -Fx \"$NIURL\"`" != "" ]
  then
    continue
  fi
  if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ]
  then
    continue
  fi
  echo "$NIURL" >> hia-parse-nodeinfo.tried
  #Skip tests if ip:port if has prior unknown result
  if [ -f data/$BIP.nodeinfo.$PORT.get.unknown ]
  then
#    echo "-Skipping $URL (exists in data/) [unknown responce]"
    continue
  fi
  if [ -f data/$BIP.nodeinfo.$PORT.get.json ]
  then
#    echo "-Skipping $URL (exists in data/) [json responce]"
    continue
  fi
  #Send HTTP request to IP:PORT
  echo -en "GET /nodeinfo.json HTTP/1.1\r\nHost: [$IP]\r\nUser-Agent: hia-parse-nodeinfo (ircerr@EFNet)\r\nAccept: */*\r\nReferer: http://hia.cjdns.ca/\r\nConnection: close\r\n\r\n" | \
  nc6 -n -w30 --idle-timeout=10 $IP $PORT 2>>/dev/null | \
  dd bs=1M count=1 2>>/dev/null > hia.tmp.$BIP.$PORT.get
  #Check for NO data in responce
  if [ "`cat hia.tmp.$BIP.$PORT.get`" == "" ]
  then
    echo "-$URL did not return any data"
    mv hia.tmp.$BIP.$PORT.get data/$BIP.nodeinfo.$PORT.get.unknown
    continue
  fi
  #Check for fail
  if [ "`cat hia.tmp.$BIP.$PORT.get|grep '^HTTP/1.[0-1]'`" == "" ]
  then
    #Not http
    echo "-$URL Not HTTP/1.x"
    #Save as unknown
    mv hia.tmp.$BIP.$PORT.get data/$BIP.nodeinfo.$PORT.get.unknown
    continue
  fi
#HTTP/1.1 400 Bad Request
  if [ "`cat hia.tmp.$BIP.$PORT.get|grep '^HTTP/1.[0-1] 200'`" == "" ]
  then
    #Not http
    echo "-$URL Not HTTP 200"
    #Save as unknown
    mv hia.tmp.$BIP.$PORT.get data/$BIP.nodeinfo.$PORT.get.unknown
    continue
  fi
#Content-Type: application/json
  if [ "`cat hia.tmp.$BIP.$PORT.get|grep '^Content-Type: .*json'`" == "" ]
  then
    #Not http
    echo "-$URL Not json"
    #Save as unknown
    mv hia.tmp.$BIP.$PORT.get data/$BIP.nodeinfo.$PORT.get.unknown
    continue
  fi
  #Got something, check it
  if [ "`cat hia.tmp.$BIP.$PORT.get|grep 'contact\|hostname\|operator'`" != "" ]
  then
    #Got something, save it
    #Add list
#echo "hia.tmp.$BIP.$PORT.get"
#cat hia.tmp.$BIP.$PORT.get
#break
    echo "# $NIURL" >>hia.nodeinfo
    if [ -f /tmp/hialog.txt 
    then
      echo "hia-parse-nodeinfo $NIURL" >> /tmp/hialog.txt
    fi
    echo "-Found: $NIURL"
    B=0
    cat hia.tmp.$BIP.$PORT.get | \
    while read L
    do
      if [ "$L" == "" ]
      then
        B=1
        continue
      fi
      if [ "$B" != "1" ]
      then
        continue
      fi
      echo "$L" >>hia.nodeinfo
    done
  fi
  mv hia.tmp.$BIP.$PORT.get data/$BIP.nodeinfo.$PORT.get.json
done

echo "hia-parse-nodeinfo complete"

) 2>&1 | tee -a hia-parse-nodeinfo.log

# EOF #
