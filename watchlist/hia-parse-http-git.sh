#!/bin/bash

# hia-parse-http-git.sh
# Check hyperboria URLs for .git/config
# Save seen url list

# Sanity check
cd /var/www/hia/watchlist/ || exit 1

# logging
(

rm hia-parse-http-git.tmp.* 2>>/dev/null

# Needful files
touch hia-parse-http-git.db.urllist
touch hia-parse-http-git.tried
touch hia-parse-http-git.found
touch hia-parse-http-git.html

TS="`date -u +%Y%m%d`"
wget -qN "http://hia.cjdns.ca/watchlist/c/walk.peers.$TS" -O - | \
tr ' ' '\n' | sort -n | uniq > hia-parse-http-git.tmp.peers

# Seed list
#if [ ! -f hia-parse-http-git.tmp.urllist ]
#then
  wget -q -U "hia-parse-http-git" -O hia-parse-http-git.tmp.urllist http://hia.cjdns.ca/watchlist/hia.urllist
#fi

# Check URLs
cat hia-parse-http-git.tmp.peers | \
while read PEER
do
  cat hia-parse-http-git.tmp.urllist | \
  grep $PEER | sort -n | \
  while read URL
  do
    if [ "`grep -F \"$URL\" hia-parse-http-git.tried`" != "" ]
    then
      continue
    fi
    echo "$URL" >> hia-parse-http-git.tried
    if [ "`grep -F \"$URL \" hia-parse-http-git.found`" != "" ]
    then
      continue
    fi
    URL_PROTO="`echo \"$URL\"|sed 's/:\/\/.*//g'`"
    if [ "$URL_PROTO" != "http" ]
    then
      continue
    fi
#    echo "URL:$URL"
    URL_IP="`echo \"$URL\"|cut -d\[ -f2|cut -d\] -f1`"
    URL_PORT="`echo \"$URL\"|cut -d\] -f2-|cut -d: -f2-|cut -d\/ -f1`"
    if [ "$URL_PORT" == "" ]
    then
      URL_PORT="80"
    fi
#    URL_PATH="`echo \"$URL\"|cut -d\] -f2-|cut -d: -f2-|cut -d\/ -f2-`"
#    if [ "$URL_PATH" == "" ]
#    then
#      URL_PATH="/"
#    fi
    URL_PATH="/.git/config"
#    echo "PROTO:$URL_PROTO IP:$URL_IP PORT:$URL_PORT PATH:$URL_PATH"
    if [ "$URL_PORT" == "80" ]
    then
      URL="$URL_PROTO://[$URL_IP]$URL_PATH"
    else
      URL="$URL_PROTO://[$URL_IP]:$URL_PORT$URL_PATH"
    fi
#    echo "URL_TEST:$URL_TEST"
    URL_FB="`echo $URL_IP|tr -d ':'`_$URL_PORT"
    if [ "$URL_PORT" == "80" ]
    then
      URL_HOST="[$URL_IP]"
    else
      URL_HOST="[$URL_IP]:$URL_PORT"
    fi
    echo -en "GET $URL_PATH HTTP/1.1\r\nHost: $URL_HOST\r\nUser-Agent: hia-parse-http-git.sh/0.01 (HIA)\r\nAccept: */*\r\nReferer: http://hia.cjdns.ca/watchlist/hia-parse-http-git.sh\r\nConnection: close\r\n\r\n" | \
    nc -n -w30 $URL_IP $URL_PORT 2>>/dev/null | \
    dd bs=1M count=5 2>>/dev/null | strings > hia-parse-http-git.tmp.$URL_FB.get
    if [ "`cat hia-parse-http-git.tmp.$URL_FB.get`" == "" ]
    then
      echo "-[$URL_IP]:$URL_PORT did not return any data"
      rm hia-parse-http-git.tmp.$URL_FB.get
      continue
    fi
    if [ "`cat hia-parse-http-git.tmp.$URL_FB.get|grep 'HTTP/1.[0-1]'`" == "" ]
    then
      echo "-[$URL_IP]:$URL_PORT Not HTTP/1.x"
      rm hia-parse-http-git.tmp.$URL_FB.get
      continue
    fi
    if [ "`cat hia-parse-http-git.tmp.$URL_FB.get|tr -d '\r'|grep -i 'plain http request was sent to https port'`" != "" ]
    then
      echo "-[$URL_IP]:$URL_PORT is HTTPS not HTTP"
      rm hia-parse-http-git.tmp.$URL_FB.get
      continue
    fi
    if [ "`cat hia-parse-http-git.tmp.$URL_FB.get|grep '^HTTP/1.[0-1] 200'`" == "" ]
    then
      echo "-[$URL_IP]:$URL_PORT Not HTTP/1.x 200"
      rm hia-parse-http-git.tmp.$URL_FB.get
      continue
    fi
    G="`strings hia-parse-http-git.tmp.$URL_FB.get|grep 'url = http'|sed 's/.*url = //g'|grep '^http'|head -n1`"
    if [ "$G" != "" ]
    then
      echo "$URL $G" >> hia-parse-http-git.found
      echo "hia-parse-http-git $URL $G" >> /tmp/hialog.txt
    fi
    rm hia-parse-http-git.tmp.$URL_FB.get
  done
done
echo

rm hia-parse-http-git.tmp.* 2>>/dev/null

) 2>&1 | tee -a hia-parse-http-git.log

(
echo "<html><body><pre>"
cat hia-parse-http-git.found | sort | \
while read URL REPO
  echo "$URL <a href=\"$REPO\">$REPO</a>"
done
echo "</pre></body></html>"
) > hia-parse-http-git.html

exit

# EOF #
