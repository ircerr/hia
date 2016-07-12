#!/bin/bash

#HIA IPlist gathering

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

#For error check
cd /var/www/hia/watchlist || exit 1

#For log
(
echo "hia-iplist begins."

touch hia.iplist

if [ ! -f hia.iplist.walk ] \
|| [ "`find . -maxdepth 1 -name hia.iplist.walk -mmin +15`" != "" ]
then
  echo -n "-Dumping WALK IPV6 list..."
  echo -n > hia.iplist.walk
  wget -q -T15 -t3 -U "`basename $0|sed 's/.sh$//g'`" -O - \
  http://hia.cjdns.ca/watchlist/c/walk.peers | \
  tr ' ' '\n' | grep '^fc' | sort | uniq > hia.iplist.walk
  WALK_F=$((`cat hia.iplist.walk|wc -l`))
  echo -n " Found $WALK_F IPs"
  echo -n > hia.iplist.walk.new
  cat hia.iplist.walk | \
  while read IP
  do
    if [ "`grep -Hx \"$IP\" hia.iplist hia.iplist.walk.new`" == "" ]
    then
      echo "$IP" >> hia.iplist.walk.new
    fi
  done
  WALK_N=$((`cat hia.iplist.walk.new|wc -l`))
  cat hia.iplist.walk.new >> hia.iplist
  rm hia.iplist.walk.new
  echo " $WALK_N NEW IPs added"
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-iplist WALK $WALK_F IPs found, $WALK_N New IPs added." >> /tmp/hialog.txt
  fi
fi

#Dump HyperDB for NEW
#if [ ! -f hia.iplist.hyperdb ] \
#|| [ "`find . -maxdepth 1 -name hia.iplist.hyperdb -mmin +15`" != "" ]
#then
#  echo -n "-Dumping hyperdb IPV6 list"
#  echo -n > hia.iplist.hyperdb
#  wget --no-proxy -6 -q -U "`basename $0|sed 's/.sh$//g'`" \
#  http://[fcf4:e309:14b5:5498:cafd:4f59:4b9c:7f84]/hyperdb/hyperdb.db \
#  -O hia.iplist.hyperdb
#  HDB_F=$((`cat hia.iplist.hyperdb|wc -l`))
#  echo -n " Found $HDB_F IPs"
#  cat hia.iplist.hyperdb | grep -xvf hia.iplist > hia.iplist.hyperdb.new
#  HDB_N=$((`cat hia.iplist.hyperdb.new|wc -l`))
#  cat hia.iplist.hyperdb.new >> hia.iplist
#  rm hia.iplist.hyperdb.new
#  echo " $HDB_N NEW IPs added"
#fi

#fc00
# http://fc00.org http://www.fc00.org
# <zlmch> I brought back www.fc00.org hyperboria map.
# If you want to contribute to its network view please get run sendGraph.py script on your node.
# https://github.com/zielmicha/fc00.org/blob/master/README.md

if [ ! -f hia.iplist.fc00 ] \
|| [ "`find . -maxdepth 1 -name hia.iplist.fc00 -mmin +15`" != "" ]
then
  echo -n "-Dumping fc00 IPV6 list..."
  echo -n > hia.iplist.fc00
  wget -q -T15 -t3 -U "`basename $0|sed 's/.sh$//g'`" \
  http://www.fc00.org/static/graph.json -O - | \
  tr '"' '\n' | grep '^fc.*:.*:.*:.*:.*:.*:.*:' | \
  sort | uniq > hia.iplist.fc00
  FC00_F=$((`cat hia.iplist.fc00|wc -l`))
  echo -n " Found $FC00_F IPs"
  cat hia.iplist.fc00 | grep -xvf hia.iplist > hia.iplist.fc00.new
  FC00_N=$((`cat hia.iplist.fc00.new|wc -l`))
  cat hia.iplist.fc00.new >> hia.iplist
  rm hia.iplist.fc00.new
  echo " $FC00_N NEW IPs added"
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-iplist fc00 $FC00_F IPs found, $FC00_N New IPs added." >> /tmp/hialog.txt
  fi
fi

# fc00 hosted by lexx
# http://[fc1d:347b:4cca:74f9:d2b2:610e:7d96:f1a9]/
#if [ ! -f hia.iplist.lexx-fc00 ] \
#|| [ "`find . -maxdepth 1 -name hia.iplist.lexx-fc00 -mmin +15`" != "" ]
#then
#  echo -n "-Dumping LEXX FC00 IPV6 list..."
#  echo -n > hia.iplist.lexx-fc00
#  wget -q -T15 -t3 -U "`basename $0|sed 's/.sh$//g'`" -O - \
#  http://[fc1d:347b:4cca:74f9:d2b2:610e:7d96:f1a9]/static/graph.json | \
#  tr '"' '\n' | grep '^fc.*:.*:.*:.*:.*:.*:.*:' | \
#  sort | uniq > hia.iplist.lexx-fc00
#  LEXX_FC00_F=$((`cat hia.iplist.lexx-fc00|wc -l`))
#  echo -n " Found $LEXX_FC00_F IPs"
#  echo -n > hia.iplist.lexx-fc00.new
#  cat hia.iplist.lexx-fc00 | \
#  while read IP
#  do
#    grep -Fqx "$IP" hia.iplist || echo "$IP" >> hia.iplist.lexx-fc00.new
#  done
#  LEXX_FC00_N=$((`cat hia.iplist.lexx-fc00.new|wc -l`))
#  cat hia.iplist.lexx-fc00.new >> hia.iplist
#  rm hia.iplist.lexx-fc00.new
#  echo " $LEXX_FC00_N NEW IPs added"
#  if [ -f /tmp/hialog.txt ]
#  then
#   echo "hia-iplist lexx-fc00 $LEXX_FC00_F IPs found, $LEXX_FC00_N New IPs added." >> /tmp/hialog.txt
#  fi
#fi
# http://h.fc00.atomshare.net/
# https://github.com/zielmicha/fc00.org
if [ ! -f hia.iplist.atom-fc00 ] \
|| [ "`find . -maxdepth 1 -name hia.iplist.atom-fc00 -mmin +15`" != "" ]
then
  echo -n "-Dumping atom FC00 IPV6 list..."
  echo -n > hia.iplist.atom-fc00
  wget -q -T15 -t3 -U "`basename $0|sed 's/.sh$//g'`" -O - \
  http://h.fc00.atomshare.net/static/graph.json | \
  tr '"' '\n' | grep '^fc.*:.*:.*:.*:.*:.*:.*:' | \
  sort | uniq > hia.iplist.atom-fc00
  ATOM_FC00_F=$((`cat hia.iplist.atom-fc00|wc -l`))
  echo -n " Found $ATOM_FC00_F IPs"
  echo -n > hia.iplist.atom-fc00.new
  cat hia.iplist.atom-fc00 | \
  while read IP
  do
    grep -Fqx "$IP" hia.iplist || echo "$IP" >> hia.iplist.atom-fc00.new
  done
  ATOM_FC00_N=$((`cat hia.iplist.atom-fc00.new|wc -l`))
  cat hia.iplist.atom-fc00.new >> hia.iplist
  rm hia.iplist.atom-fc00.new
  echo " $ATOM_FC00_N NEW IPs added"
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-iplist atom-fc00 $ATOM_FC00_F IPs found, $ATOM_FC00_N New IPs added." >> /tmp/hialog.txt
  fi
fi

# HUB
#http://dev.hub.hyperboria.net/api/v1/map/graph/node.json
#http://dev.hub.hyperboria.net/api/v1/map/graph/edge.json
if [ ! -f hia.iplist.hub ] \
|| [ "`find . -maxdepth 1 -name hia.iplist.hub -mmin +15`" != "" ]
then
  echo -n "-Dumping HUB IPV6 list..."
  echo -n > hia.iplist.hub
  wget -q -T15 -t3 -U "`basename $0|sed 's/.sh$//g'`" -O - \
  http://api.hyperboria.net/v0/nodes/known.json | \
  tr ',' '\n' | grep '"fc' | sed 's/.*"fc/fc/g' | \
  sed 's/"$//g' > hia.iplist.hub
  cat hia.iplist.hub | sort | uniq > hia.iplist.hub.new
  mv hia.iplist.hub.new hia.iplist.hub
  HUB_F=$((`cat hia.iplist.hub|wc -l`))
  echo -n " Found $HUB_F IPs"
  echo -n > hia.iplist.hub.new
  cat hia.iplist.hub | \
  while read IP
  do
    grep -Fqx "$IP" hia.iplist || echo "$IP" >> hia.iplist.hub.new
  done
  HUB_N=$((`cat hia.iplist.hub.new|wc -l`))
  cat hia.iplist.hub.new >> hia.iplist
  rm hia.iplist.hub.new
  echo " $HUB_N NEW IPs added"
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-iplist HUB $HUB IPs found, $HUB_N New IPs added." >> /tmp/hialog.txt
  fi
fi

# HA
if [ ! -f hia.iplist.ha ] \
|| [ "`find . -maxdepth 1 -name hia.iplist.ha -mmin +15`" != "" ]
then
  echo -n "-Dumping HA IPV6 list..."
  echo -n > hia.iplist.ha
  wget -q -T15 -t3 -U "`basename $0|sed 's/.sh$//g'`" -O - \
  http://h.cjdns.ca/ha.db.txt http://h.ircerr.ca/cjdns/ha.db.txt | \
  tr ' ' '\n' | grep ^fc | \
  sort | uniq | \
  while read IP
  do
    IPX="`padip $IP`"
    if [ "$IPX" == "" ]
    then
      continue
    fi
    echo "$IPX" >> hia.iplist.ha
  done
  HA_F=$((`cat hia.iplist.ha|wc -l`))
  echo -n " Found $HA_F IPs"
  cat hia.iplist.ha | grep -xvf hia.iplist > hia.iplist.ha.new
  HA_N=$((`cat hia.iplist.ha.new|wc -l`))
  cat hia.iplist.ha.new >> hia.iplist
  rm hia.iplist.ha.new
  echo " $HA_N NEW IPs added"
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-iplist HA $HA_F IPs found, $HA_N New IPs added." >> /tmp/hialog.txt
  fi
fi

#http://bloor.ansuz.xyz:8003/knownNodes
if [ ! -f hia.iplist.hdb ] \
|| [ "`find . -maxdepth 1 -name hia.iplist.hdb -mmin +15`" != "" ]
then
  echo -n "-Dumping HDB IPV6 list..."
  echo -n > hia.iplist.hdb
  wget -q -T15 -t3 -U "`basename $0|sed 's/.sh$//g'`" -O - \
  http://bloor.ansuz.xyz:8003/knownNodes | \
  tr ',' '\n' | grep '"fc' | sed 's/.*"fc/fc/g' | sed 's/"$//g' | \
  sort | uniq > hia.iplist.hdb
  HDB_F=$((`cat hia.iplist.hdb|wc -l`))
  echo -n " Found $HDB_F IPs"
  cat hia.iplist.hdb | grep -xvf hia.iplist > hia.iplist.hdb.new
  HDB_N=$((`cat hia.iplist.hdb.new|wc -l`))
  cat hia.iplist.hdb.new >> hia.iplist
  rm hia.iplist.hdb.new
  echo " $HDB_N NEW IPs added"
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-iplist HDB $HDB_F IPs found, $HDB_N New IPs added." >> /tmp/hialog.txt
  fi
fi

HIA_IPS=$((`cat hia.iplist | wc -l`))
if [ -f /tmp/hialog.txt ]
then
  echo "hia-iplist $HIA_IPS total known." >> /tmp/hialog.txt
fi
echo "$HIA_IPS total known."
echo "hia-iplist complete."

exit

) 2>&1 | tee -a hia-iplist.log

#EOF#
