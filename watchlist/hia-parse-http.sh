#!/bin/bash

# hia-parse-http.sh
# 20140928

# Check results of HIA Scanner
# Test all open ports for HTTP results
# Generate list of all known sites

# Read IP:PORT from hia.portlist
# Check for HTTP responce
# Save found to hia.urllist

# Sanity Check
cd /var/www/hia/watchlist/ || exit 1

touch hia.iplist
touch hia.portlist
touch hia.urllist
touch hia-parse-http.tried
mkdir -p data/

TS="`date -u +%Y%m%d`"
wget -qN "http://hia.cjdns.ca/watchlist/c/walk.peers.$TS" -O - | \
tr ' ' '\n' | sort -n | uniq > hia-parse-http.tmp.peers


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

echo "hia-parse-http begins"

IPSNUM=$((`cat hia.portlist|cut -d\[ -f2|cut -d\] -f1|sort|uniq|wc -l`))
echo "-Checking results for $IPSNUM IPs"

cat hia.portlist | \
cut -d\[ -f2 | cut -d\] -f1 | \
sort -n | uniq | \
while read IP
do
  #Pad IPV6 to include missing zeros
  IP="`padip $IP`"
  #Remove :'s for file/dir name usage
  if [ "`grep \"$IP\" hia-parse-http.tmp.peers`" == "" ]
  then
    continue
  fi
  if [ "`grep -F \"$IP\" hia.iplist`" == "" ]
  then
    continue
  fi
  BIP="`echo $IP|tr -d ':'`"
  if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ]
  then
    continue
  fi
#  #Skip if IP found in open portlist
#  if [ "`cat hia.urllist|grep \"\[$IP\]\"`" != "" ]
#  then
##    echo "-Skipping $IP (exists in urllist)"
#    continue
#  fi
  cat hia.portlist | grep "$IP" | cut -d\] -f2 | cut -d: -f2 | \
  grep TCP | cut -d\  -f1 | \
  while read PORT
  do
    if [ "`cat hia-parse-http.tried|grep -x \"$IP $PORT\"`" != "" ]
    then
      continue
    fi
    #Skip if not up NOW
    if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ]
    then
#      echo "-Skipping $IP (No ICMP reply)"
      continue
    fi
    echo "$IP $PORT" >> hia-parse-http.tried
#    #Skip tests for known/unwanted ports
#    if [ "$PORT" == "21" ] || [ "$PORT" == "22" ] \
#    || [ "$PORT" == "25" ] || [ "$PORT" == "53" ]
#    then
#      continue
#    fi
    #Skip tests if ip:port found in urllist file
    if [ "`cat hia.urllist|grep \"^http.*://\[$IP\]:$PORT\"`" != "" ]
    then
#      echo "-Skipping [$IP]:$PORT (exists in urllist)"
      continue
    fi
    #Skip tests if ip:port if has prior unknown result
    if [ -f data/$BIP.http.$PORT.get.unknown ]
    then
#      echo "-Skipping [$IP]:$PORT (exists in data/) [unknown responce]"
      continue
    fi
    #Send HTTP request to IP:PORT
    echo -en "GET / HTTP/1.1\r\nHost: [$IP]\r\nUser-Agent: hia-parse-http (ircerr@EFNet)\r\nAccept: */*\r\nReferer: http://hia.cjdns.ca/\r\nConnection: close\r\n\r\n" | \
    nc -n -w30 $IP $PORT 2>>/dev/null | \
    dd bs=1M count=5 2>>/dev/null | strings > hia-parse-http.tmp.$IP.$PORT.get
    #Check for NO data in responce
    if [ "`cat hia-parse-http.tmp.$IP.$PORT.get`" == "" ]
    then
      echo "-[$IP]:$PORT did not return any data"
      mv hia-parse-http.tmp.$IP.$PORT.get data/$BIP.http.$PORT.get.unknown
      continue
    fi
    #Check for fail
    if [ "`cat hia-parse-http.tmp.$IP.$PORT.get|grep '^HTTP/1.[0-1]'`" == "" ]
    then
      #Not http
      echo "-[$IP]:$PORT Not HTTP/1.x"
      #Save as unknown
      mv hia-parse-http.tmp.$IP.$PORT.get data/$BIP.http.$PORT.get.unknown
      continue
    fi
    #Got something, save it
    mv hia-parse-http.tmp.$IP.$PORT.get data/$BIP.http.$PORT.get
    #Default Discription as URL
    U="http://[$IP]:$PORT/"
    #check for 400 the plain http request was sent to https port
    if [ "`cat data/$BIP.http.$PORT.get|tr -d '\r'|grep -i 'plain http request was sent to https port'`" != "" ]
    then
      #Use https for protocol, URL as description
      U="https://[$IP]:$PORT/"
    fi
    #Add URL to urllist
    echo "-[$IP]:$PORT Adding $U"
    echo "$U" >>hia.urllist
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-http $U" >> /tmp/hialog.txt
    fi
  done
#  break
done

echo "hia-parse-http complete"
) 2>&1 | tee -a hia-parse-http.log

if [ -x ./bithunt-submit.sh ]
then
  ./bithunt-submit.sh
fi

# EOF #

