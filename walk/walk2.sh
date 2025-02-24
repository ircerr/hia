#!/bin/bash

# walk.sh
# dump all peers from all nodes using router admin getpeers api command

if [ "$CJDNSDIR" == "" ]
then
  CJDNSDIR="/root/cjdns"
fi
if [ ! -d "$CJDNSDIR/tools/" ]
then
  echo "--ERROR: missing tools/ in $CJDNSDIR. Edit $0 first."
  exit
fi

if [ -d tmp/walk/ ] \
&& [ -f tmp/walk/walk.log ]
then
  TS=`date -u -r tmp/walk/walk.log +%Y%m%d%H%M%S`
  echo "-Archving $TS"
  mkdir -p $TS/
  mv tmp/walk/* $TS/
  mkdir -p olddata/
  tar -cJf olddata/$TS.tar.xz $TS/ && rm -rf $TS/
  echo "-Complete"
fi
if [ "$1" != "" ]
then
  exit 1
fi
if [ ! -L tmp ]
then
  ln -s /tmp/ tmp
fi
mkdir -p tmp/walk/

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
  $CJDNSDIR/cjdnstool cexec "ping" 2>>/dev/null | grep '"q": "pong"'
}

# Save to walk.pubkey
function savekey() {
  NODEPK="`echo $1|sed 's/.k$//g'`"
  NODEIP="$2"
  if [ "`grep -x \"$NODEPK $NODEIP\" walk.pubkey 2>>/dev/null`" == "" ]
  then
    echo "-- adding $NODEPK $NODEIP to walk.pubkey" 1>&2
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
    echo "-- adding $NODEVER.$NODEPK to walk.version" 1>&2
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
#sfwm2gnp002nc9fkucmx37fnrnxb5sldjhlkj288s35gu047fk90.k fc17:275f:8171:073c:b567:4595:e12c:7684
  NODEIP="`$CJDNSDIR/cjdnstool util key2ip6 $NODEPK.k|cut -d\  -f2`"
  NODEIP="`padip $NODEIP`"
  if [ "$NODEIP" == "" ]
  then
    return
  fi
  savekey $NODEPK $NODEIP
  echo "$NODEIP"
}
# add to todo
function addtodo() {
  NODEPK="`echo \"$1\"|cut -d\. -f6-7|sed 's/.k$//g'`"
  if [ "`grep \"$NODEPK\" tmp/walk/walk.paths.todo`" != "" ]
  then
    echo "--Not adding $NODEPK from $1" 1>&2
    return
  fi
  echo "$1" >> tmp/walk/walk.paths.todo
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
  rm tmp/walk/getPeers.$NODE* 2>>/dev/null
  echo -n > tmp/walk/paths.$NODE
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
#cjdnstool cexec RouterModule_getPeers --path=<String> [--nearbyPath=<String>] [--timeout=<Int>]
#      $CJDNSDIR/tools/cexec "RouterModule_getPeers(\"$NODE\", $TIMEOUT, undefined)" \
      $CJDNSDIR/cjdnstool cexec RouterModule_getPeers --path=$NODE --timeout=$TIMEOUT \
      > tmp/walk/getPeers.$NODE.$PAGE 2>>/dev/null
    else
#      $CJDNSDIR/tools/cexec "RouterModule_getPeers(\"$NODE\", $TIMEOUT, \"$LASTPATH\")" \
      $CJDNSDIR/cjdnstool cexec RouterModule_getPeers --node=$NODE --nearbyPath=$LASTPATH --timeout=$TIMEOUT \
      > tmp/walk/getPeers.$NODE.$PAGE 2>>/dev/null
    fi
    if [ "`cat tmp/walk/getPeers.$NODE.$PAGE | grep -v '^$'`" == "" ] \
    || [ "`cat tmp/walk/getPeers.$NODE.$PAGE | grep '"result": "timeout"'`" != "" ]
    then
      RT=$((RT+1))
      if [ $RT -ge $TRIES ]
      then
        if [ "`cat tmp/walk/getPeers.$NODE.$PAGE | grep '"result": "timeout"'`" != "" ]
        then
          echo "--ERROR Timeout" 1>&2
        else
          echo "--ERROR No data" 1>&2
        fi
        echo "-- adding $NODE to walk.path.errors" 1>&2
        echo "$NODE" >> tmp/walk/walk.paths.errors
        break
      fi
      sleep $(($RT*1))
      continue
    fi
    RT=0
    touch tmp/walk/paths.$NODE
    cat tmp/walk/getPeers.$NODE.$PAGE | \
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
      if [ "`grep -x \"$PV.$PP.$PK.k\" tmp/walk/paths.$NODE`" == "" ]
      then
        echo "-- adding $PV.$PP.$PK.k to paths.$NODE" 1>&2
        echo "$PV.$PP.$PK.k" >> tmp/walk/paths.$NODE
      fi
      if [ "$NODE" != "0000.0000.0000.0001" ]
      then
        #Add to known
        if [ "`cat tmp/walk/walk.peers.tmp 2>>/dev/null | grep -x \"$NODE_IP $PPIP\"`" == "" ] \
        && [ "$NODEIP" != "" ]
        then
          echo "-- adding $NODEIP $PPIP to walk.peers.tmp" 1>&2
          echo "$NODEIP $PPIP" >> tmp/walk/walk.peers.tmp
        fi
        echo "-Splice $PV.$PP.$PK.k $NODE"
        PPNODE="`echo $NODE|cut -d\. -f2-5`"
        PPS="`$CJDNSDIR/tools/splice $PP $PPNODE`"
        echo "  $PP + $PPNODE = $PPS"
        if [ "$PPS" == "ffff.ffff.ffff.ffff" ] \
        || [ "`echo \"$PPS\"|grep '^0'`" == "" ]
        then
          echo "--ERROR: got $PPS from splice of $PP+$PPNODE for $P" 1>&2
          continue
        fi
        if [ "`grep -x \"$PV.$PPS.$PK.k\" tmp/walk/walk.paths`" == "" ]
        then
          echo "-- adding $PV.$PPS.$PK.k to walk.paths" 1>&2
          echo "$PV.$PPS.$PK.k" >> tmp/walk/walk.paths
          addtodo "$PV.$PPS.$PK.k"
        fi
      else
        if [ "`grep -x \"$PV.$PP.$PK.k\" tmp/walk/walk.paths`" == "" ]
        then
          echo "-- adding $PV.$PP.$PK.k to walk.paths" 1>&2
          echo "$PV.$PP.$PK.k" >> tmp/walk/walk.paths
          addtodo "$PV.$PP.$PK.k"
        fi
      fi
    done
    LASTPATH="`cat tmp/walk/paths.$NODE|grep '^v'|tail -n1|cut -d\. -f2-5`"
    if [ "$LASTPATH" == "$LASTLASTPATH" ]
    then
#      echo "--No more paths for $NODE" 1>&2
      if [ "$NODE" != "0000.0000.0000.0001" ]
      then
        echo "-- adding $NODE to walk.paths.done" 1>&2
        echo "$NODE" >> tmp/walk/walk.paths.done
      fi
      break
    fi
    LASTLASTPATH="$LASTPATH"
    PAGE=$(($PAGE+1))
    if [ "$PAGE" -gt 50 ]
    then
      echo "--ERROR 50+ pages?" 1>&2
      echo "$NODE" >> tmp/walk/walk.paths.errors
      break
    fi
  done
}

(
TIMEOUT=10000
TRIES=3
TODONUM=0
MAXBGS=15
BGS=0

rm tmp/walk/walk.tmp* 2>>/dev/null
touch walk.peers
touch walk.pubkey
touch walk.version
echo -n > tmp/walk/walk.paths
echo -n > tmp/walk/walk.paths.todo
echo -n > tmp/walk/walk.paths.done
echo -n > tmp/walk/walk.paths.errors
echo -n > tmp/walk/walk.peers.tmp

# Get local nodes direct peers' paths via peerStats
echo
echo "-Getting paths from local node"
dumpPeers "0000.0000.0000.0001"

echo
echo "-Crawling paths"
while :
do
  if [ "`cjdnsPing`" == "" ]
  then
    echo "--ERROR no cjnsPing (crashed?!?)" 1>&2
    break
  fi
  PATHS_KNOWN=$((`wc -l tmp/walk/walk.paths|cut -d\  -f1`))
  PATHS_TODO=$((`wc -l tmp/walk/walk.paths.todo|cut -d\  -f1`))
  PATHS_DONE=$((`wc -l tmp/walk/walk.paths.done|cut -d\  -f1`))
  PATHS_ERRORS=$((`wc -l tmp/walk/walk.paths.errors|cut -d\  -f1`))
  NODES="$((`cat tmp/walk/walk.paths* | cut -d\. -f6 | sort | uniq | wc -l`))"
  PUBKEYS="$((`cat walk.pubkey | cut -d\. -f1 | sort | uniq | wc -l`))"
  VERSIONS="$((`cat walk.version | cut -d\. -f2 | sort | uniq | wc -l`))"
  TODONUM=$(($TODONUM+1))
  if [ $TODONUM -gt $PATHS_TODO ]
  then
    echo "-- No more paths todo" 1>&2
    break
  fi
  echo
  echo "BGS $BGS/$MAXBGS PATHS KNOWN:$PATHS_KNOWN CURRENT:$TODONUM TODO:$PATHS_TODO DONE:$PATHS_DONE ERRORS:$PATHS_ERRORS NODES:$NODES"
  NEXTPATH="`cat tmp/walk/walk.paths.todo|head -n $TODONUM|tail -n1`"
  if [ "$NEXTPATH" == "" ]
  then
    echo "-No more todo"
    break
  fi
  PD="`grep -x \"$NEXTPATH\" tmp/walk/walk.paths.done`"
  if [ "$PD"  != "" ]
  then
    echo "--ERROR Prior done $NEXTPATH, skipping ($PD)" 1>&2
    continue
  fi
  PE="`grep -x \"$NEXTPATH\" tmp/walk/walk.paths.errors`"
  if [ "$PE" != "" ]
  then
    echo "--ERROR Prior error $NEXTPATH, skipping ($PE)" 1>&2
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
  PT="`cat tmp/walk/walk.paths.done | cut -d\. -f6 | sort | uniq | grep -x $PK`"
  if [ "$PT"  != "" ]
  then
    echo "--Skip tried node $NEXTPATH ($PT)" 1>&2
    continue
  fi
#  echo "PV:$PV PP:$PP PK:$PK"
#  echo "-Trying $NEXTPATH"
  BGS=$((`ls /tmp/walk/|grep 'walk.getpeers'|wc -l`))
  while [ $BGS -ge $MAXBGS ]
  do
    BGS=$((`ls /tmp/walk/|grep 'walk.getpeers'|wc -l`))
    if [ $BGS -ge $MAXBGS ]
    then
      echo "[$BGS/$MAXBGS] Waiting for BGs" 1>&2
      sleep 10
      continue
    fi
    break
  done
  ( touch tmp/walk/walk.getpeers.$NEXTPATH; dumpPeers "$NEXTPATH"; rm tmp/walk/walk.getpeers.$NEXTPATH ) & &> /dev/null
  sleep 1
done

BGS=$((`ls /tmp/walk/ | grep 'walk.getpeers'|wc -l`))
while [ $BGS -ge 1 ]
do
  BGS=$((`ls /tmp/walk/ | grep 'walk.getpeers'|wc -l`))
  if [ $BGS -ge 1 ]
  then
    echo "[$BGS/$MAXBGS] Waiting for final BGs" 1>&2
    sleep 15
    continue
  fi
  break
done

echo "--Cleaning up" 1>&2

#Add to walk.peers (all peerings ever seen)
cat walk.peers tmp/walk/walk.peers.tmp | sort -n | uniq > walk.peers.new && \
mv walk.peers.new walk.peers
#Add to walk.peers.today
touch "walk.peers.`date -u +%Y%m%d`"
cat tmp/walk/walk.peers.tmp "walk.peers.`date -u +%Y%m%d`" | sort | uniq > walk.peers.new && \
mv walk.peers.new "walk.peers.`date -u +%Y%m%d`"
#Add to walk.peers.month
touch "walk.peers.`date -u +%Y%m`"
cat tmp/walk/walk.peers.tmp "walk.peers.`date -u +%Y%m`" | sort | uniq > walk.peers.new && \
mv walk.peers.new "walk.peers.`date -u +%Y%m`"


echo "--All done." 1>&2
echo

) 2>&1 | tee -a tmp/walk/walk.log

exit

# EOF #
