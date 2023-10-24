#!/bin/bash

# hia-parse-proxy.sh
# Check for open proxies using known http server ports

# Sanity check
cd /var/www/hia/watchlist/ || exit 1

# Needful files
touch hia-parse-proxy.tried

## GET http:// test via clearnet domain
function test_proxy_get_clearnet_domain() {
  IP=$1
  PORT=$2
  TF="`echo $IP.$PORT|tr -d ':'`"
  (
  echo -en "GET http://cjdns.ca/azenv.php?$TF.GCD HTTP/1.1\r\n"
  echo -en "User-Agent: hia-parse-proxy.sh (hia; ircerr@HypeIRC)\r\n"
  echo -en "Referer: http://hia.cjdns.ca/watchlist/\r\n"
  echo -en "Proxy-Connection: close\r\n"
  echo -en "Connection: close\r\n"
  echo -en "X-ProxyID: $IP.$PORT.GCD\r\n"
  echo -en "Host: cjdns.ca\r\n"
  echo -en "\r\n"
  ) | \
  ( nc -n -w30 $IP $PORT 2>>/dev/null ) | \
  dd bs=1M count=5 2>>/dev/null | strings > hia-parse-proxy.tmp.$TF.azenv.gcd
  cat hia-parse-proxy.tmp.$TF.azenv.gcd | grep '^HTTP/1.[0-1]'
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.gcd | grep '^HTTP/1.[0-1]'`" == "" ]
  then
    echo "--non HTTP"
    rm hia-parse-proxy.tmp.$TF.azenv.gcd
    return
  fi
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.gcd | grep '^HTTP/1.[0-1] 200'`" == "" ]
  then
    echo "--non 200"
    rm hia-parse-proxy.tmp.$TF.azenv.gcd
    return
  fi
#REMOTE_ADDR = 170.75.163.51
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.gcd | grep '^REMOTE_ADDR '`" == "" ]
  then
    echo "--non REMOTE_ADDR"
    rm hia-parse-proxy.tmp.$TF.azenv.gcd
    return
  fi
  echo "$IP $PORT GCD" >>hia-parse-proxy.found
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-parse-proxy [$IP]:$PORT GCD" >> /tmp/hialog.txt
  fi
  rm hia-parse-proxy.tmp.$TF.azenv.gcd
  return
}

## GET http:// test via clearnet IP4
function test_proxy_get_clearnet_ip4() {
  IP=$1
  PORT=$2
  TF="`echo $IP.$PORT|tr -d ':'`"
  (
  echo -en "GET http://170.75.163.51/azenv.php?$TF.GCIP4 HTTP/1.1\r\n"
  echo -en "User-Agent: hia-parse-proxy.sh (hia; ircerr@HypeIRC)\r\n"
  echo -en "Referer: http://hia.cjdns.ca/watchlist/\r\n"
  echo -en "Proxy-Connection: close\r\n"
  echo -en "Connection: close\r\n"
  echo -en "X-ProxyID: $IP.$PORT.GCIP4\r\n"
  echo -en "Host: cjdns.ca\r\n"
  echo -en "\r\n"
  ) | \
  ( nc -n -w30 $IP $PORT 2>>/dev/null ) | \
  dd bs=1M count=5 2>>/dev/null | strings > hia-parse-proxy.tmp.$TF.azenv.gcip4
  cat hia-parse-proxy.tmp.$TF.azenv.gcip4 | grep '^HTTP/1.[0-1]'
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.gcip4 | grep '^HTTP/1.[0-1]'`" == "" ]
  then
    echo "--non HTTP"
    rm hia-parse-proxy.tmp.$TF.azenv.gcip4
    return
  fi
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.gcip4 | grep '^HTTP/1.[0-1] 200'`" == "" ]
  then
    echo "--non 200"
    rm hia-parse-proxy.tmp.$TF.azenv.gcip4
    return
  fi
#REMOTE_ADDR = 170.75.163.51
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.gcip4 | grep '^REMOTE_ADDR '`" == "" ]
  then
    echo "--non REMOTE_ADDR"
    rm hia-parse-proxy.tmp.$TF.azenv.gcip4
    return
  fi
  echo "$IP $PORT GCIP4" >>hia-parse-proxy.found
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-parse-proxy [$IP]:$PORT GCIPV4" >> /tmp/hialog.txt
  fi
  rm hia-parse-proxy.tmp.$TF.azenv.gcip4
  return
}

## GET http:// test via hyperboria domain
function test_proxy_get_hype_domain() {
  IP=$1
  PORT=$2
  TF="`echo $IP.$PORT|tr -d ':'`"
  (
  echo -en "GET http://h.cjdns.ca/azenv.php?$TF.GHD HTTP/1.1\r\n"
  echo -en "User-Agent: hia-parse-proxy.sh (hia; ircerr@HypeIRC)\r\n"
  echo -en "Referer: http://hia.cjdns.ca/watchlist/\r\n"
  echo -en "Proxy-Connection: close\r\n"
  echo -en "Connection: close\r\n"
  echo -en "X-ProxyID: $IP.$PORT.GHD\r\n"
  echo -en "Host: cjdns.ca\r\n"
  echo -en "\r\n"
  ) | \
  ( nc -n -w30 $IP $PORT 2>>/dev/null ) | \
  dd bs=1M count=5 2>>/dev/null | strings > hia-parse-proxy.tmp.$TF.azenv.ghd
  cat hia-parse-proxy.tmp.$TF.azenv.ghd | grep '^HTTP/1.[0-1]'
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.ghd | grep '^HTTP/1.[0-1]'`" == "" ]
  then
    echo "--non HTTP"
    rm hia-parse-proxy.tmp.$TF.azenv.ghd
    return
  fi
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.ghd | grep '^HTTP/1.[0-1] 200'`" == "" ]
  then
    echo "--non 200"
    rm hia-parse-proxy.tmp.$TF.azenv.ghd
    return
  fi
#REMOTE_ADDR = 170.75.163.51
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.ghd | grep '^REMOTE_ADDR '`" == "" ]
  then
    echo "--non REMOTE_ADDR"
    rm hia-parse-proxy.tmp.$TF.azenv.ghd
    return
  fi
  echo "$IP $PORT GHD" >>hia-parse-proxy.found
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-parse-proxy [$IP]:$PORT GHD" >> /tmp/hialog.txt
  fi
  rm hia-parse-proxy.tmp.$TF.azenv.ghd
  return
}

## GET http:// test via hyperboria IP6
function test_proxy_get_hype_ip6() {
  IP=$1
  PORT=$2
  TF="`echo $IP.$PORT|tr -d ':'`"
  (
  echo -en "GET http://[fcf4:e309:14b5:5498:cafd:4f59:4b9c:7f84]/azenv.php?$TF.GHIP6 HTTP/1.1\r\n"
  echo -en "User-Agent: hia-parse-proxy.sh (hia; ircerr@HypeIRC)\r\n"
  echo -en "Referer: http://hia.cjdns.ca/watchlist/\r\n"
  echo -en "Proxy-Connection: close\r\n"
  echo -en "Connection: close\r\n"
  echo -en "X-ProxyID: $IP.$PORT.GHIP6\r\n"
  echo -en "Host: cjdns.ca\r\n"
  echo -en "\r\n"
  ) | \
  ( nc -n -w30 $IP $PORT 2>>/dev/null ) | \
  dd bs=1M count=5 2>>/dev/null | strings > hia-parse-proxy.tmp.$TF.azenv.ghip6
  cat hia-parse-proxy.tmp.$TF.azenv.ghip6 | grep '^HTTP/1.[0-1]'
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.ghip6 | grep '^HTTP/1.[0-1]'`" == "" ]
  then
    echo "--non HTTP"
    rm hia-parse-proxy.tmp.$TF.azenv.ghip6
    return
  fi
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.ghip6 | grep '^HTTP/1.[0-1] 200'`" == "" ]
  then
    echo "--non 200"
    rm hia-parse-proxy.tmp.$TF.azenv.ghip6
    return
  fi
#REMOTE_ADDR = 170.75.163.51
  if [ "`cat hia-parse-proxy.tmp.$TF.azenv.ghip6 | grep '^REMOTE_ADDR '`" == "" ]
  then
    echo "--non REMOTE_ADDR"
    rm hia-parse-proxy.tmp.$TF.azenv.ghip6
    return
  fi
  echo "$IP $PORT GHIP6" >>hia-parse-proxy.found
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-parse-proxy [$IP]:$PORT GHIP6" >> /tmp/hialog.txt
  fi
  rm hia-parse-proxy.tmp.$TF.azenv.ghip6
  return
}

#Main
(
cat hia.urllist | sort -n | uniq | \
while read URL
do
  IP="`echo \"$URL\"|cut -d\[ -f2|cut -d\] -f1`"
  if [ "`grep -F \"$IP\" hia.iplist`" == "" ]
  then
    continue
  fi
  PORT="`echo \"$URL\"|cut -d\] -f2-|cut -d: -f2|cut -d\/ -f1`"
  TF="`echo $IP.$PORT|tr -d ':'`"
  if [ "$TF" == "fcf4e30914b55498cafd4f594b9c7f84.80" ]
  then
    continue
  fi
  nc -nvz -w15 $IP $PORT 2>&1 | grep -q 'succeeded' || continue
#  echo "IP:$IP PORT:$PORT"
  if [ "`cat hia-parse-proxy.tried|grep -xF \"$TF GCD\"`" == "" ]
  then
    echo "$TF GCD" >> hia-parse-proxy.tried
    echo "IP:$IP PORT:$PORT GCD"
    test_proxy_get_clearnet_domain $IP $PORT
  fi
  if [ "`cat hia-parse-proxy.tried|grep -xF \"$TF GCIP4\"`" == "" ]
  then
    echo "$TF GCIP4" >> hia-parse-proxy.tried
    echo "IP:$IP PORT:$PORT GCIP4"
    test_proxy_get_clearnet_ip4 $IP $PORT
  fi
  if [ "`cat hia-parse-proxy.tried|grep -xF \"$TF GHD\"`" == "" ]
  then
    echo "$TF GHD" >> hia-parse-proxy.tried
    echo "IP:$IP PORT:$PORT GHD"
    test_proxy_get_hype_domain $IP $PORT
  fi
  if [ "`cat hia-parse-proxy.tried|grep -xF \"$TF GHIP6\"`" == "" ]
  then
    echo "$TF GHIP6" >> hia-parse-proxy.tried
    echo "IP:$IP PORT:$PORT GHIP6"
    test_proxy_get_hype_ip6 $IP $PORT
  fi
done

exit
) 2>&1 | tee -a hia-parse-proxy.log

# EOF #

