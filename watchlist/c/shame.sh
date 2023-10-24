#!/bin/bash

# shame.sh
# Wall of Shame for outdated peers
# And peers w/ outdated direct peers

#v0.r5u3uydmm784wr8dp7v80t7g3jwd9bk03prwrgpg41q6910vmkj0
#v12.lmmrp2y5vhmx96kfjw17bh59gvluhxnv6404nk7yn6md76xzrs40
#00f0x6149741v2qqs41sk9sj2gz3x5v888d7vntgsnxd7s2u52w0 fc81:cf2a:7799:829f:1109:d66a:bf46:09d1
(
echo "# Outdated node SHAME list"
echo "#node_ver node_ip"
echo "# peer_ver peer_ip"

cat walk.version | sort | \
grep -v '^v0' | \
while read L
do
  #Parse deets of peer
  V="`echo $L|cut -d\. -f1`"
  if [ "$V" == "v18" ]
  then
    continue
  fi
  K="`echo $L|cut -d\. -f2`"
  I="`grep $K walk.pubkey|cut -d\  -f2`"
  if [ "$I" == "" ]
  then
    continue
  fi
  echo "$V $I"
  #Get peers of peer
  F="walk.peers.`date -u +%Y%m`"
  cat $F | grep "$I" | tr ' ' '\n' | sort | uniq | grep -v "$I" | \
  while read PI
  do
    PK="`grep $PI walk.pubkey|cut -d\  -f1`"
    PV="`grep $PK walk.version|cut -d\. -f1`"
    if [ "$PK" == "" ] || [ "$PV" == "" ]
    then
      continue
    fi
    if [ "$PV" == "v18" ]
    then
      continue
    fi
    echo " $PV $PI"
  done
done
) > shame.tmp && \
mv shame.tmp shame.txt



