#!/bin/bash

# walk.sh
# dump all peers from all nodes using router admin getpeers api command

function cleanup() {
  if [ -d tmp/data/ ] \
  && [ -f tmp/walk.log ]
  then
    TS=`date -u -r tmp/walk.log +%Y%m%d%H%M%S`
    echo "-Archving $TS"
    mkdir -p $TS/
    mv tmp/data/ $TS/
    mv tmp/walk.log $TS/
    mv tmp/walk.paths* $TS/
    mkdir -p olddata/
    tar -cJf olddata/$TS.tar.xz $TS/ && rm -rf $TS/
    echo "-Complete"
  fi
  return
}

## functions
#Pad IP - fill in missing zeros
function padip() {
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
      fi
      break
    done
  done
  if [ "$PADIP" != "" ]
  then
    ip="$PADIP"
  fi
  echo "$ip"
  return
}

# Test cjdns is working
function cjdnsPing() {
  for TRY in 1 2 3 4 5 6 7 8 9
  do
    PONG="$($CJDNSDIR/tools/cexec "ping()" 2>>/dev/null | grep '"q": "pong"')"
    if [ "$PONG" != "" ]
    then
      echo "$PONG"
      break
    fi
    sleep $TRY.$RANDOM
  done
  return
}

# Save to walk.pubkey
function savekey() {
  NODEPK="`echo $1|sed 's/.k$//g'`"
  NODEIP="$2"
  if [ "`grep -x \"$NODEPK $NODEIP\" walk.pubkey 2>>/dev/null`" == "" ]
  then
#    echo "-- adding $NODEPK $NODEIP to walk.pubkey" 1>&2
    echo "$NODEPK $NODEIP" >> walk.pubkey
  fi
}

# Save to walk.version
function savever() {
  NODEVER=$1
  NODEPK=$2
  if [ "`grep -x \"$NODEVER.$NODEPK\" walk.version`" != "" ]
  then
    return
  fi
  if [ "`cat walk.version|cut -d\. -f2|grep \"$NODEPK\"`" == "" ]
  then
#    echo "-- adding $NODEVER.$NODEPK to walk.version" 1>&2
    echo "$NODEVER.$NODEPK" >> walk.version
    return
  fi
  cat walk.version | grep -v $NODEPK > walk.version.new
  mv walk.version.new walk.version
  echo "-- updating $NODEVER.$NODEPK in walk.version" 1>&2
  echo "$NODEVER.$NODEPK" >> walk.version
  return
}

# pubkey to ip
function keytoip() {
  NODEPK="`echo $1|sed 's/.k$//g'`"
#  NODEIP="`$CJDNSDIR/target/release/publictoip6 $NODEPK.k`"
#└─# cjdnstool util key2ip6 tcbvl7zf6d8127d1phgq1t01jqdtug7qwmfcg97lcstt22ct7jg0.k
#tcbvl7zf6d8127d1phgq1t01jqdtug7qwmfcg97lcstt22ct7jg0.k fcde:5b9e:fe85:5af7:5368:6dff:729d:f859
  NODEIP="$($CJDNSDIR/cjdnstool util key2ip6 ${NODEPK}.k|sed 's/.* //g')"
  NODEIP="`padip $NODEIP`"
  if [ "$NODEIP" == "" ]
  then
    echo "---FAILED to convert NODEPK:$NODEPK to IP" 1>&2
    return
  fi
  savekey $NODEPK $NODEIP
  echo "$NODEIP"
}

# Dump direct peers from node
function dumpPeers() {
  if [ "`cjdnsPing`" == "" ]
  then
    echo "--ERROR no cjnsPing (crashed?!?)" 1>&2
    return
  fi
  NODE="$1"
  if [ "$NODE" == "0000.0000.0000.0001" ]
  then
    #LocalNode
    NODEPV=""
    NODEPP="$NODE"
    NODEPK=""
    NODEIP=""
  else
    NODEPV="`echo \"$NODE\"|cut -d\. -f1`"
    NODEPP="`echo \"$NODE\"|cut -d\. -f2-5`"
    NODEPK="`echo \"$NODE\"|cut -d\. -f6`"
    if [ "$NODEPK" != "" ]
    then
      NODEIP="`keytoip $NODEPK`"
      savever $NODEPV $NODEPK
    fi
    if [ "$NODEPP" == "0000.0000.0000.0001" ] \
    || [ "$NODEPP" == "ffff.ffff.ffff.ffff" ] \
    || [ "`echo \"$NODEPP\"|grep '^0'`" == "" ]
    then
      echo "--Ignoring bogus path $NODEPP" 1>&2
      return
    fi
  fi
  echo "-dumpPeers $NODE"
  rm tmp/data/getPeers.$NODE* 2>>/dev/null
  echo -n > tmp/data/paths.$NODE
  PAGE=0
  RT=0
  LASTPATH=""
  while :
  do
    if [ "`cjdnsPing`" == "" ]
    then
      echo "--ERROR no cjnsPing (crashed?!?)" 1>&2
      break
    fi
    if [ "$LASTPATH" == "" ]
    then
      $CJDNSDIR/tools/cexec "RouterModule_getPeers(\"$NODE\", $TIMEOUT, undefined)" \
      > tmp/data/getPeers.$NODE.$PAGE 2>>/dev/null
    else
      $CJDNSDIR/tools/cexec "RouterModule_getPeers(\"$NODE\", $TIMEOUT, \"$LASTPATH\")" \
      > tmp/data/getPeers.$NODE.$PAGE 2>>/dev/null
    fi
    if [ "`cat tmp/data/getPeers.$NODE.$PAGE | grep -v '^$'`" == "" ] \
    || [ "`cat tmp/data/getPeers.$NODE.$PAGE | grep '"result": "timeout"'`" != "" ]
    then
      RT=$((RT+1))
      if [ $RT -ge $TRIES ]
      then
        if [ "`cat tmp/data/getPeers.$NODE.$PAGE | grep '"result": "timeout"'`" != "" ]
        then
          echo "--ERROR Timeout" 1>&2
        else
          echo "--ERROR No data" 1>&2
        fi
#        echo "-- adding $NODE to walk.path.errors" 1>&2
        echo "$NODE" >> tmp/walk.paths.errors
        break
      fi
      sleep $(($RT))
      continue
    fi
    RT=0
    touch tmp/data/paths.$NODE
    cat tmp/data/getPeers.$NODE.$PAGE | \
    grep '"v.*\..*\..*\..*\..*\.k"' | cut -d\" -f2 | \
    while read P
    do
#v17.0000.0000.0000.001f.c94sls20x5shql6r4z4nvqlrs9pcppgj2h41m1bntzk60j5wrs40.k
      PV="`echo \"$P\"|cut -d\. -f1`"
      PP="`echo \"$P\"|cut -d\. -f2-5`"
      PK="`echo \"$P\"|cut -d\. -f6`"
      if [ "$PK" != "" ]
      then
        PPIP="`keytoip $PK`"
        savever $PV $PK
      fi
#      echo "PV:$PV PP:$PP PK:$PK"
      if [ "$PP" == "0000.0000.0000.0001" ]
      then
#        echo "--Skipping local node in $P" 1>&2
        continue
      fi
      if [ "`grep -x \"$PV.$PP.$PK.k\" tmp/data/paths.$NODE`" == "" ]
      then
#        echo "-- adding $PV.$PP.$PK.k to paths.$NODE" 1>&2
        echo "$PV.$PP.$PK.k" >> tmp/data/paths.$NODE
      fi
      if [ "$NODE" != "0000.0000.0000.0001" ]
      then
        #Add to known
        if [ "`cat tmp/walk.peers.tmp 2>>/dev/null | grep -x \"$NODE_IP $PPIP\"`" == "" ] \
        && [ "$NODEIP" != "" ]
        then
#          echo "-- adding $NODEIP $PPIP to walk.peers.tmp" 1>&2
          echo "$NODEIP $PPIP" >> tmp/walk.peers.tmp
        fi
#        echo "-Splice $PV.$PP.$PK.k $NODE"
        PPNODE="`echo $NODE|cut -d\. -f2-5`"
        PPS="`$CJDNSDIR/tools/splice $PP $PPNODE`"
 #       echo "  $PP + $PPNODE = $PPS"
        if [ "$PPS" == "ffff.ffff.ffff.ffff" ] \
        || [ "`echo \"$PPS\"|grep '^0'`" == "" ]
        then
          echo "--ERROR: got $PPS from splice of $PP+$PPNODE for $P" 1>&2
          continue
        fi
        if [ "`grep -x \"$PV.$PPS.$PK.k\" tmp/walk.paths`" == "" ]
        then
#          echo "-- adding $PV.$PPS.$PK.k to walk.paths" 1>&2
          echo "$PV.$PPS.$PK.k" >> tmp/walk.paths
          PT="`cat tmp/walk.paths.todo tmp/walk.paths.done | cut -d\. -f6 | sort | uniq | grep -x $PK`"
          if [ "$PT" == "" ]
          then
#            echo "-- adding $PK.k to walk.paths.todo" 1>&2
            echo "$PV.$PPS.$PK.k" >> tmp/walk.paths.todo
          fi
        fi
      else
        if [ "`grep -x \"$PV.$PP.$PK.k\" tmp/walk.paths`" == "" ]
        then
#          echo "-- adding $PV.$PP.$PK.k to walk.paths" 1>&2
          echo "$PV.$PP.$PK.k" >> tmp/walk.paths
          PT="`cat tmp/walk.paths.todo tmp/walk.paths.done | cut -d\. -f6 | sort | uniq | grep -x $PK`"
          if [ "$PT" == "" ]
          then
#            echo "-- adding $PK.k to walk.paths.todo" 1>&2
            echo "$PV.$PP.$PK.k" >> tmp/walk.paths.todo
          fi
        fi
      fi
    done
    LASTPATH="`cat tmp/data/paths.$NODE|grep '^v'|tail -n1|cut -d\. -f2-5`"
    if [ "$LASTPATH" == "$LASTLASTPATH" ]
    then
#      echo "--No more paths for $NODE" 1>&2
      if [ "$NODE" != "0000.0000.0000.0001" ]
      then
#        echo "-- adding $NODE to walk.paths.done" 1>&2
        echo "$NODE" >> tmp/walk.paths.done
      fi
      break
    fi
    LASTLASTPATH="$LASTPATH"
    PAGE=$(($PAGE+1))
    if [ "$PAGE" -gt 50 ]
    then
      echo "--ERROR 50+ pages?" 1>&2
      echo "$NODE" >> tmp/walk.paths.errors
      break
    fi
  done
}

cd /var/www/cjdns/hia/watchlist/walk/ || exit 1

if [ ! -L tmp ]
then
  ln -s /tmp/ tmp
fi


(
if [ "$CJDNSDIR" == "" ]
then
  CJDNSDIR="/home/cjdns/cjdns"
fi
if [ ! -d "$CJDNSDIR" ]
then
  CJDNSDIR="/root/cjdns"
fi
if [ ! -d "$CJDNSDIR/tools/" ]
then
  echo "--ERROR: missing tools/ in $CJDNSDIR. Edit $0 first."
  exit
fi

cleanup
if [ "$1" != "" ]
then
  exit 1
fi

TIMEOUT=10000
TRIES=3

rm walk.tmp* 2>>/dev/null
mkdir -p tmp/data/
touch walk.peers
touch walk.pubkey
touch walk.version
echo -n > tmp/walk.paths
echo -n > tmp/walk.paths.todo
echo -n > tmp/walk.paths.done
echo -n > tmp/walk.paths.errors
echo -n > tmp/walk.peers.tmp
# Get local nodes direct peers' paths via peerStats
echo
echo "-Getting paths from local node"
dumpPeers "0000.0000.0000.0001"

#cat tmp/walk.paths >> tmp/walk.paths.todo
echo
echo "-Crawling paths"
while :
do
  if [ "`cjdnsPing`" == "" ]
  then
    echo "--ERROR no cjnsPing (crashed?!?)" 1>&2
    break
  fi
  PATHS_KNOWN=$((`wc -l tmp/walk.paths|cut -d\  -f1`))
  PATHS_TODO=$((`wc -l tmp/walk.paths.todo|cut -d\  -f1`))
  PATHS_DONE=$((`wc -l tmp/walk.paths.done|cut -d\  -f1`))
  PATHS_ERRORS=$((`wc -l tmp/walk.paths.errors|cut -d\  -f1`))
  NODES="$((`cat tmp/walk.paths* | cut -d\. -f6 | sort | uniq | wc -l`))"
  PUBKEYS="$((`cat walk.pubkey | cut -d\. -f1 | sort | uniq | wc -l`))"
  VERSIONS="$((`cat walk.version | cut -d\. -f2 | sort | uniq | wc -l`))"
  echo
  echo "PATHS KNOWN:$PATHS_KNOWN TODO:$PATHS_TODO DONE:$PATHS_DONE ERRORS:$PATHS_ERRORS NODES:$NODES PKS:$PUBKEYS VERS:$VERSIONS"
  NEXTPATH="`head -n1 tmp/walk.paths.todo`"
  if [ "$NEXTPATH" == "" ]
  then
    echo "-No more todo"
    break
  fi
  PD="`grep -x \"$NEXTPATH\" tmp/walk.paths.done`"
  if [ "$PD"  != "" ]
  then
#    echo "--ERROR Prior done $NEXTPATH, skipping ($PD)" 1>&2
    cat tmp/walk.paths.todo | grep -xv "$NEXTPATH" > tmp/walk.paths.todo.new
    mv tmp/walk.paths.todo.new tmp/walk.paths.todo
    continue
  fi
  PE="`grep -x \"$NEXTPATH\" tmp/walk.paths.errors`"
  if [ "$PE" != "" ]
  then
#    echo "--ERROR Prior error $NEXTPATH, skipping ($PE)" 1>&2
    cat tmp/walk.paths.todo | grep -xv "$NEXTPATH" > tmp/walk.paths.todo.new
    mv tmp/walk.paths.todo.new tmp/walk.paths.todo
    continue
  fi
#v17.0000.0000.0000.001f.c94sls20x5shql6r4z4nvqlrs9pcppgj2h41m1bntzk60j5wrs40.k
  PV="`echo \"$NEXTPATH\"|cut -d\. -f1`"
  PP="`echo \"$NEXTPATH\"|cut -d\. -f2-5`"
  PK="`echo \"$NEXTPATH\"|cut -d\. -f6`"
  if [ "$PP" == "0000.0000.0000.0001" ]
  then
#    echo "--Skipping local node $NEXTPATH" 1>&2
    continue
  fi
  PT="`cat tmp/walk.paths.done | cut -d\. -f6 | sort | uniq | grep -x $PK`"
  if [ "$PT"  != "" ]
  then
#    echo "--Skip tried node $NEXTPATH ($PT)" 1>&2
    cat tmp/walk.paths.todo | grep -xv "$NEXTPATH" > tmp/walk.paths.todo.new
    mv tmp/walk.paths.todo.new tmp/walk.paths.todo
    continue
  fi
#  echo "PV:$PV PP:$PP PK:$PK"
  sleep .1 || break
#  echo "-Trying $NEXTPATH"
  dumpPeers "$NEXTPATH"

#  cat tmp/walk.paths | grep -xvf tmp/walk.paths.done | \
#  grep -xvf tmp/walk.paths.errors >> tmp/walk.paths.todo
  cat tmp/walk.paths.todo | sort | uniq > tmp/walk.paths.todo.new
  mv tmp/walk.paths.todo.new tmp/walk.paths.todo
  cat tmp/walk.paths.todo | grep -xv "$NEXTPATH" > tmp/walk.paths.todo.new
  mv tmp/walk.paths.todo.new tmp/walk.paths.todo
done

echo "--DONE"
wc -l walk.peers tmp/walk.peers.tmp
#Add to walk.peers (all peerings ever seen)
cat walk.peers tmp/walk.peers.tmp | sort -n | uniq > walk.peers.new
mv walk.peers.new walk.peers
wc -l walk.peers tmp/walk.peers.tmp
#Add to walk.peers.today
touch "walk.peers.`date -u +%Y%m%d`"
cat tmp/walk.peers.tmp "walk.peers.`date -u +%Y%m%d`" | sort | uniq > walk.peers.new
mv walk.peers.new "walk.peers.`date -u +%Y%m%d`"
#Add to walk.peers.month
touch "walk.peers.`date -u +%Y%m`"
cat tmp/walk.peers.tmp "walk.peers.`date -u +%Y%m`" | sort | uniq > walk.peers.new
mv walk.peers.new "walk.peers.`date -u +%Y%m`"

) 2>&1 | tee -a tmp/walk.log

cleanup


exit
