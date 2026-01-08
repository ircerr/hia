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
cd /var/www/cjdns/hia/watchlist || exit 1

#For log
(
echo "hia-iplist begins."

touch hia.iplist
touch hia.iplist.all

if [ ! -f hia.iplist.walk ] \
|| [ "`find . -maxdepth 1 -name hia.iplist.walk -mmin +15`" != "" ]
then
  echo -n "-Dumping WALK IPV6 list..."
  echo -n > hia.iplist.walk
  wget -q -T15 -t3 -U "`basename $0|sed 's/.sh$//g'`" -O - \
  http://hia.cjdns.ca/watchlist/walk/walk.peers.`date -u +%Y%m%d` | \
  tr ' ' '\n' | grep '^fc' | sort | uniq > hia.iplist.walk.new
  if [ "`head hia.iplist.walk.new`" != "" ]
  then
    mv hia.iplist.walk.new hia.iplist.walk
  else
   rm hia.iplist.walk.new
  fi
else
  echo -n " -Using cached list..."
fi
WALK_F=$((`cat hia.iplist.walk|wc -l`))
echo -n " Found $WALK_F IPs"

echo -n > hia.iplist.walk.new
cat hia.iplist.walk | sort | uniq | \
while read IP
do
  IP="`padip $IP`"
  echo "$IP" >> hia.iplist.walk.new
done
mv hia.iplist.walk.new hia.iplist.walk

cat hia.iplist.walk | grep -xvf hia.iplist.all > hia.iplist.walk.new
WALK_N=$((`cat hia.iplist.walk.new|wc -l`))
rm hia.iplist.walk.new
echo " $WALK_N NEW IPs added"
mv hia.iplist.walk hia.iplist

echo -n > hia.iplist.new
cat hia.iplist | sort | uniq | \
while read IP
do
  IP="`padip $IP`"
  echo "$IP" >> hia.iplist.new
done
mv hia.iplist.new hia.iplist

cat hia.iplist.all hia.iplist | sort | uniq > hia.iplist.all.new
mv hia.iplist.all.new hia.iplist.all

HIA_IPS=$((`cat hia.iplist | wc -l`))
HIA_IPS_ALL=$((`cat hia.iplist.all | wc -l`))
if [ -f /tmp/hialog.txt ]
then
  echo "hia-iplist WALK $WALK_F IPs found, $WALK_N New IPs added, $HIA_IPS live, $HIA_IPS_ALL total known." >> /tmp/hialog.txt
fi
echo "hia-iplist WALK $WALK_F IPs found, $WALK_N New IPs added, $HIA_IPS live, $HIA_IPS_ALL total known."
echo "hia-iplist complete."

exit

) 2>&1 | tee -a hia-iplist.log

#EOF#
