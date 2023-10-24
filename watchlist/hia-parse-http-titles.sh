#!/bin/bash

# hia-parse-http-titles.sh
# Check hyperboria URLs for titles
# Save seen titles list

# Sanity check
cd /var/www/hia/watchlist/ || exit 1

# logging
(

rm hia-parse-http-titles.tmp.* 2>>/dev/null

# Needful files
touch hia-parse-http-titles.db.urllist
touch hia-parse-http-titles.db.titles
touch hia-parse-http-titles.db.domains
touch hia-parse-http-titles.tmp.closed
touch hia-parse-http-titles.tmp.fail

# Seed URL list
#if [ ! -f hia-parse-http-titles.tmp.urllist ]
#then
  wget -q -U "hia-parse-http-titles" -O hia-parse-http-titles.tmp.urllist http://hia.cjdns.ca/watchlist/hia.urllist
#fi

# Check URLs
cat hia-parse-http-titles.tmp.urllist | \
sort | \
while read URL
do
  if [ "`grep -F \"$URL \" hia-parse-http-titles.db.titles`" != "" ]
  then
    continue
  fi
  if [ "`grep -Fx \"$URL\" hia-parse-http-titles.tmp.closed hia-parse-http-titles.tmp.fail`" != "" ]
  then
    continue
  fi
  URL_PROTO="`echo \"$URL\"|sed 's/:\/\/.*//g'`"
  if [ "$URL_PROTO" != "http" ]
  then
    continue
  fi
#  echo "URL:$URL"
  URL_IP="`echo \"$URL\"|cut -d\[ -f2|cut -d\] -f1`"
  URL_PORT="`echo \"$URL\"|cut -d\] -f2-|cut -d: -f2-|cut -d\/ -f1`"
  if [ "$URL_PORT" == "" ]
  then
    URL_PORT="80"
  fi
  URL_PATH="`echo \"$URL\"|cut -d\] -f2-|cut -d: -f2-|cut -d\/ -f2-`"
  if [ "$URL_PATH" == "" ]
  then
    URL_PATH="/"
  fi
#  echo "PROTO:$URL_PROTO IP:$URL_IP PORT:$URL_PORT PATH:$URL_PATH"
  URL_TEST="$URL_PROTO://[$URL_IP]:$URL_PORT$URL_PATH"
#  echo "URL_TEST:$URL_TEST"
  URL_FB="`echo $URL_IP|tr -d ':'`_$URL_PORT"
  if [ "$URL_PORT" == "80" ]
  then
    URL_HOST="[$URL_IP]"
  else
    URL_HOST="[$URL_IP]:$URL_PORT"
  fi
  STATUS="`nc -nvz -w30 $URL_IP $URL_PORT 2>&1`"
#Connection refused
#Permission denied
  if [ "`echo \"$STATUS\"|grep 'Connection refused$\|Permission denied$'`" != "" ]
  then
    echo "-$URL Skip (refused)"
    echo "$URL" >> hia-parse-http-titles.tmp.closed
    continue
  fi
#timeout while connecting
  if [ "`echo \"$STATUS\"|grep 'timeout while connecting\|timed out'`" != "" ]
  then
    echo "-$URL Skip (timeout)"
#    echo "$URL" >> hia-parse-http-titles.tmp.closed
    continue
  fi
#Unknown responce (Connection to fce1:2a4e:2214:22c1:f0fe:59af:e6b8:b8ab 1776 port [tcp/*] succeeded!)
  if [ "`echo \"$STATUS\"|grep 'succeeded'`" == "" ]
  then
    echo "--$URL Unknown responce ($STATUS)"
    continue
  fi
  echo -en "GET $URL_PATH HTTP/1.1\r\nHost: $URL_HOST\r\nUser-Agent: hia-parse-http-titles.sh/0.01 (HIA)\r\nAccept: */*\r\nReferer: http://hia.cjdns.ca/watchlist/hia-parse-http-titles.sh\r\nConnection: close\r\n\r\n" | \
  nc -n -w30 $URL_IP $URL_PORT 2>>/dev/null | \
  dd bs=1M count=5 2>>/dev/null | strings > hia-parse-http-titles.tmp.$URL_FB.get
  if [ "`cat hia-parse-http-titles.tmp.$URL_FB.get`" == "" ]
  then
    echo "-[$URL_IP]:$URL_PORT did not return any data"
    rm hia-parse-http-titles.tmp.$URL_FB.get
    continue
  fi
  if [ "`cat hia-parse-http-titles.tmp.$URL_FB.get|grep 'HTTP/1.[0-1]'`" == "" ]
  then
    echo "-[$URL_IP]:$URL_PORT Not HTTP/1.x"
    rm hia-parse-http-titles.tmp.$URL_FB.get
    continue
  fi
  if [ "`cat hia-parse-http-titles.tmp.$URL_FB.get|tr -d '\r'|grep -i 'plain http request was sent to https port'`" != "" ]
  then
    echo "-[$URL_IP]:$URL_PORT is HTTPS not HTTP"
    rm hia-parse-http-titles.tmp.$URL_FB.get
    echo "$URL" >> hia-parse-http-titles.tmp.fail
    continue
  fi
  if [ "`cat hia-parse-http-titles.tmp.$URL_FB.get|grep '^HTTP/1.[0-1] 200'`" == "" ]
  then
    echo "-[$URL_IP]:$URL_PORT Not HTTP/1.x 200"
    rm hia-parse-http-titles.tmp.$URL_FB.get
    echo "$URL" >> hia-parse-http-titles.tmp.fail
    continue
  fi
  T="`cat hia-parse-http-titles.tmp.$URL_FB.get|strings|tr '\n' ' '|grep -i '<title>'|sed 's/.*<title>//gi'|cut -d\< -f1`"
  if [ "$T" == "" ]
  then
    T="`cat hia-parse-http-titles.tmp.$URL_FB.get|strings|tr '\n' ' '|grep -i '<h1>'|sed 's/.*<h1>//gi'|cut -d\< -f1`"
  fi
  if [ "$T" == "" ]
  then
    T="`cat hia-parse-http-titles.tmp.$URL_FB.get|strings|grep -v '^$'|grep -i '[a-z]'|grep -v ': \|^HTTP'|cut -d\> -f2|cut -d\< -f1|grep -v '^$'|head -n1`"
  fi
  rm hia-parse-http-titles.tmp.$URL_FB.get
  T="`echo \"$T\"|tr -d '{\|}'`"
  if [ "`echo \"$T\"|tr -d ' '`" != "" ]
  then
    echo "--$URL TITLE: $T"
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-http-titles $URL $T" >> /tmp/hialog.txt
    fi
    echo "$URL $T" >> hia-parse-http-titles.db.titles
  else
    echo "--$URL No title detected"
  fi
done
echo

rm hia-parse-http-titles.tmp.* 2>>/dev/null

) 2>&1 | tee -a hia-parse-http-titles.log

(
echo "<html><body><pre>"
cat hia-parse-http-titles.db.titles | sort | \
while read URL TITLE
do
  echo "$URL <a href=\"$URL\">$TITLE</a>"
done
echo "</pre></body></html>"
) > hia-parse-http-titles.html

exit

# EOF #
