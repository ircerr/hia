#!/bin/bash

# shame.sh
# Wall of Shame for outdated peers
# And peers w/ outdated direct peers

#v0.r5u3uydmm784wr8dp7v80t7g3jwd9bk03prwrgpg41q6910vmkj0
#v12.lmmrp2y5vhmx96kfjw17bh59gvluhxnv6404nk7yn6md76xzrs40
#00f0x6149741v2qqs41sk9sj2gz3x5v888d7vntgsnxd7s2u52w0 fc81:cf2a:7799:829f:1109:d66a:bf46:09d1
(
echo "# Outdated node SHAME list"
echo "# #node_ver node_ip"
echo "# -peer_ver peer_ip"

cat ../watchlist/hia.iplist | sort | uniq | \
while read IP
do
  #Parse PubK of peer
  K="`grep \"$IP\" walk.pubkey|cut -d\  -f1`"
  #Parse deets of peer
  V="`grep \"$K\" walk.version|cut -d\. -f1`"
  if [ "$V" == "v0" ] \
  || [ "$V" == "v22" ]
  then
    continue
  fi
  echo "#$V $IP"
  #Get peers of peer
  F="walk.peers.`date -u +%Y%m`"
  cat $F | grep "$IP" | tr ' ' '\n' | sort | uniq | grep -v "$IP" | \
  while read PIP
  do
    if [ "`grep \"$PIP\" ../watchlist/hia.iplist`" == "" ]
    then
      continue
    fi
    PK="`grep $PIP walk.pubkey|cut -d\  -f1`"
    PV="`grep $PK walk.version|cut -d\. -f1`"
    if [ "$PK" == "" ] || [ "$PV" == "" ]
    then
      continue
    fi
    if [ "$PV" == "v22" ]
    then
      continue
    fi
    echo "-$PV $PIP"
  done
done
) | tee shame.tmp && \
mv shame.tmp shame.txt
