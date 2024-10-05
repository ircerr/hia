#!/bin/bash

# hia-parse-http-ak.sh
# 20240704

# Sanity Check
cd /var/www/hia/watchlist/ || exit 1

touch hia-parse-http-ak.tried
touch hia-parse-http-ak.found

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

function test_url() {
  URL="$1"
  shift
  IP="$1"
  shift
  TESTURI="$1"
  shift
  TESTEXP="$*"
  if [ "`grep \"^$URL $TESTURI$\" hia-parse-http-ak.tried`" != "" ]
  then
    return
  fi
  echo "$URL $TESTURI" >> hia-parse-http-ak.tried
  echo -en "GET $TESTURI HTTP/1.1\r\nHost: [$IP]\r\nUser-Agent: hia-parse-http-ak.sh (HIA)\r\nAccept: */*\r\nReferer: http://hia.cjdns.ca/\r\nConnection: close\r\n\r\n" | \
  nc -n -w30 $IP $PORT 2>>/dev/null | \
  dd bs=1M count=5 2>>/dev/null | strings | grep -q "$TESTEXP" || return
  if [ "`grep \"^$URL $TESTURI$\" hia-parse-http-ak.found`" == "" ]
  then
    echo "$URL $TESTURI" >> hia-parse-http-ak.found
    echo "$URL $TESTURI added."
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-http-ak $URL $TESTURI added." >> /tmp/hialog.txt
    fi
  fi
  return
}

(
echo "hia-parse-http-ak begins"

TS="`date -u +%Y%m%d`"
wget -qN "http://hia.cjdns.ca/watchlist/c/walk.peers.$TS" -O - | \
tr ' ' '\n' | sort -n | uniq > hia-parse-http-ak.tmp.peers

cat hia.urllist | sort | \
while read URL
do
  #Skip if exists
  if [ "`grep -Fx \"$URL\" hia-parse-http-ak.tried hia-parse-http-ak.found`" != "" ]
  then
    continue
  fi
  IP="`echo \"$URL\"|cut -d\[ -f2|cut -d\] -f1`"
  IP="`padip $IP`"
  if [ "`grep \"$IP\" hia-parse-http-ak.tmp.peers`" == "" ]
  then
    continue
  fi
  if [ "`grep -F \"$IP\" hia.iplist`" == "" ]
  then
    continue
  fi
# curl http://z.kaotisk-hund.com:8610
#{"message":"Hello! Welcome to Arching Kaos API! See available routes below!","routes":{"GET":[{"welcome":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/"},{"gathered_zblocks":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/see"},{"gathered_zchain_zlatest_pairs":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/seens"},{"node_local_chain":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/chain"},{"node_local_peers":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/peers"},{"node_local_info":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/node_info"},{"node_local_zlatest":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/zlatest"},{"latest_known_mined_block":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/slatest"},{"show_mined_block":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/sblock"},{"getMerkleTree":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/mrk/:mkr"}],"POST":[{"send_me_a_zchain_link":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/announce/zchain"},{"send_me_a_zblock":"http://[fc59:6076:6299:6776:c13d:fbb2:1226:ead0]:8610/v0/announce/zblock"}]}}
  test_url "$URL" "$IP" "/" "Hello! Welcome to Arching Kaos API!"

# curl -s http://z.kaotisk-hund.com:8610/v0/node_info
#{
#  "profile": {
#    "following": "QmSsgAfdF1TiAn5nVjfkqhpwnTjZcsUXpghVXXMm5XC8Cr",
#    "foo": "bar",
#    "nickname": "kaotisk",
#    "repositories": "QmV4cdeMnjiXkAV33sRf5paxf4p4CHgaboCbeV6KXLNC91"
#  },
#  "genesis": "QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH",
#  "gpg": "QmYrZcFtHmPWiQjGeWqLh3aQzDeTjmNdEY8cgygdG1FY6q",
#  "zchain": "k51qzi5uqu5dgapvk7bhxmchuqya9immqdpbz0f1r91ckpdqzub63afn3d5apr",
#  "zlatest": "QmVkP6QR3XFjxhdiyu5xnC72xD6zDu1zbGJhkyoN4NYpXi"
#}
  test_url "$URL" "$IP" "/v0/node_info" "zlatest"

# curl -s http://z.kaotisk-hund.com:8610/v0/peers
#[{"cjdns":{"public_key":"nn0890kwv8cpyp9p3pc88u2j54165cr29ch3bq5d8thdl5uvn2j0.k","ip":"fc42:7cfa:b830:e988:f192:717f:6576:ed12"},"node_info":{"profile":{"nickname":"kaotiskhund"},"genesis":"QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH","gpg":"QmVaLxTZKrU6TKFJajEEvvmpWtveWghcEFYB3Doio8K5jm","zchain":"k51qzi5uqu5dij4nqveonxs9lzgsh3li204zym7tjt9gsheaudjnnycs2o04jy","zlatest":"QmdjZVFVGGsuM1rsrF5kUfL7YBBNmwheHJbXcRuBhjf4CW"}}]
  test_url "$URL" "$IP" "/v0/peers" "public_key"

done

echo "hia-parse-http-ak complete"
) 2>&1 | tee -a hia-parse-http-ak.log

# EOF #
