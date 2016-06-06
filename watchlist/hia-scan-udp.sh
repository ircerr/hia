#!/bin/bash

#HIA Scanner
#PortScan all known IPs for OPEN Ports
#Save IP:PORT list of results

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

do_ping () {
  IP=$1
  /home/cjdns/cjdns/tools/cexec "RouterModule_pingNode(\"$IP\")" 2>&1 | \
  grep '"result": "pong"' && echo "[api] $IP UP" 1>&2
  #|| echo "[api] $IP DOWN" 1>&2
}

function do_scan () {
  IP=$1
  BIP="`echo $IP|tr -d ':'`"
  PID="`ps axw|grep -v grep|grep $BIP.udp|cut -b -6|tr -d ' '`"
  PING="`ping6 -c 5 -i .5 -w 10 $IP 2>&1 | grep 'bytes from'`"
  if [ "$PING" == "" ]
  then
    PING="`do_ping $IP`"
  fi
  if [ "$PID" != "" ]
  then
    if [ "$PING" == "" ]
    then
#      if [ -f /tmp/hialog.txt ]
#      then
#        echo "do_scan udp - ERR no PONG ($PING) from PID:$PID for IP:$IP" >> /tmp/hialog.txt
#      fi
      kill $PID &>/dev/null
#      rm data/$BIP.udp* &>/dev/null
      return
    fi
    echo "do_scan - ERR nmap running (`ps axw|grep -v grep|grep $BIP`)"
    return
  fi
  if [ "$PING" == "" ]
  then
    return
  fi
  if [ -f data/$BIP.udp.nmap ]
  then
    echo "do_scan - ERR file data/$BIP.udp.nmap exists"
    return
  fi
  echo -n > data/$BIP.udp.nmap
 (
  nmap -PN -T4 -v -6 $IP -sU -r -n --host-timeout $((60*60*48))s \
  $PORTSCMD --open -oG data/$BIP.udp.oG &> data/$BIP.udp.log
  PING="`ping6 -c 5 -i .5 -w 10 $IP 2>&1 | grep 'bytes from'`"
  if [ "$PING" == "" ]
  then
    PING="`do_ping $IP`"
  fi
  if [ "$PING" == "" ]
  then
    echo "do_scan - ERR $IP is is DOWN"
    rm data/$BIP.udp.*
#    if [ -f /tmp/hialog.txt ]
#    then
#      echo "ERR [$IP] UDP Fail (Host no longer UP)" >> /tmp/hialog.txt
#    fi
    return
  fi
  if [ "`cat data/$BIP.udp.oG|grep '^# Nmap done'`" == "" ]
  then
    echo "DONE $IP UDP [nmap fail]" >>data/$BIP.udp.nmap
    rm data/$BIP.udp.nmap
    if [ -f /tmp/hialog.txt ]
    then
      echo "ERR [$IP] UDP Fail" >> /tmp/hialog.txt
    fi
    return
  fi
  if [ "`cat data/$BIP.udp.oG|grep '^# Nmap done at .* (0 hosts up) scanned'`" != "" ]
  then
    echo "DONE $IP UDP [host down]"  >> data/$BIP.udp.nmap
    rm data/$BIP.udp.nmap
    rm data/$BIP.udp.log data/$BIP.udp.oG
    return
  fi
  H="`cat data/$BIP.udp.oG | grep ^Host | cut -d\  -f2-|grep '/open/'`"
  if [ "$H" == "" ]
  then
    echo "DONE $IP UDP [no open ports]" >> data/$BIP.udp.nmap
#    rm data/$BIP.udp.log data/$BIP.udp.oG
    return
  fi
#  echo "H:$H" >> data/$BIP.udp.nmap
  PORTS="`echo $H|sed 's/.*Ports: //g'|tr ',' '\n'|grep open|cut -d\/ -f1|tr '\n' ' '|sed 's/  / /g'|sed 's/ $//g'`"
#  echo "PORTS:$PORTS" >> data/$BIP.udp.nmap
  for PORT in $PORTS
  do
    if [ "`cat hia.portlist|grep -x \"\[$IP\]:$PORT UDP\"`" == "" ]
    then
      echo "[$IP]:$PORT UDP" >> hia.portlist
      if [ -f /tmp/hialog.txt ]
      then
        echo "hia-scan-udp [$IP]:$PORT UDP OPEN" >> /tmp/hialog.txt
      fi
    fi
#    if [ "$PORT" == "21" ] || [ "$PORT" == "22" ] \
#    || [ "$PORT" == "25" ] || [ "$PORT" == "53" ]
#    then
#      continue
#    fi
  done
  echo "DONE $IP UDP [`echo $H|sed 's/.*Ports: //g'|tr ',' '\n'|grep open|cut -d\/ -f1|wc -l` open ports]" >>data/$BIP.udp.nmap
  ) &>/dev/null &
  return
}

function check_duds () {
  ps axw | grep -v grep | grep 'nmap .*6 fc.*data/fc.*oG' | \
  sed 's/ pts.*6 fc/ fc/g' | sed 's/ -s.*oG$//g' | \
  while read L
  do
    PID="`echo \"$L\"|cut -d\  -f1`"
    IP="`echo \"$L\"|cut -d\  -f2`"
    BIP="`echo $IP|tr -d ':'`"
    if [ "$PID" == "" ]; then continue; fi
    if [ "$IP" == "" ]; then continue; fi
    PING="`ping6 -c 5 -i .5 -w 10 $IP 2>&1 | grep 'bytes from'`"
    if [ "$PING" == "" ]
    then
      PING="`do_ping $IP`"
    fi
    if [ "$PING" == "" ]
    then
#      if [ -f /tmp/hialog.txt ]
#      then
#        echo "DUD [$IP] Fail (Host no longer UP)" >> /tmp/hialog.txt
#      fi
      kill $PID &>/dev/null
#      rm data/$BIP.* &>/dev/null
    fi
  done
  return
}

#MAIN#

# Sanity check
cd /var/www/hia/watchlist/ || exit 1

#For log
(
echo "hia-scan-udp begins."

MAXBG=25

touch hia.iplist
touch hia.portlist
touch hia.urllist

mkdir -p data/

R="`ls data/*.udp.nmap 2>>/dev/null|wc -l`"
echo "-Found $R already running."

IPSNUM=$((`cat hia.iplist|wc -l`))
echo "-Scanning $IPSNUM IPs"
IPSDONE=0
#if [ "`head -n5 hia.urllist`" == "" ]
#then
#  PORTSCMD="-F"
#else
  PORTSCMD="-p1-65535"
#fi
S=0
cat hia.iplist | \
sort -n | \
while read IPX
do
  IPSDONE=$(($IPSDONE+1))
  IP="`padip $IPX`"
  BIP="`echo $IP|tr -d ':'`"
  PID="`ps axw|grep -v grep|grep $BIP.udp|cut -b -6|tr -d ' '`"
  PING="`ping6 -c 5 -i .5 -w 10 $IP 2>&1 | grep 'bytes from'`"
  if [ "$PING" == "" ]
  then
    PING="`do_ping $IP`"
  fi
  if [ "$PID" != "" ]
  then
    if [ "$PING" == "" ]
    then
#      if [ -f /tmp/hialog.txt ]
#      then
#        echo "udp - ERR no PONG ($PING) from PID:$PID for IP:$IP" >> /tmp/hialog.txt
#      fi
      kill $PID &>/dev/null
#      rm data/$BIP.udp* &>/dev/null
      continue
    fi
#    echo "udp - ERR nmap running (`ps axw|grep -v grep|grep $BIP`)"
    continue
  fi
  if [ "$PING" == "" ]
  then
#    echo "-$IP No PONG"
    continue
  fi
  if [ -f data/$BIP.udp.nmap ]
  then
    echo "-$IP busy - file data/$BIP.udp.nmap exists"
    continue
  fi
  if [ "`ps axw|grep -v grep|grep $BIP.tcp`" != "" ]
  then
    echo "-$IP busy - nmap running (`ps axw|grep -v grep|grep $BIP`)"
    continue
  fi
  if [ -f data/$BIP.udp.oG ] \
  && [ "`cat data/$BIP.udp.oG|grep '^# Nmap done'`" == "" ]
  then
    echo "-$IP Removing old UDP FAIL"
    rm data/$BIP.udp.*
  fi
  if [ -f data/$BIP.udp.oG ] \
  && [ "`cat data/$BIP.udp.oG|grep '^# Nmap done at .* (0 hosts up) scanned'`" != "" ]
  then
    echo "-$IP Removing old UDP DOWN"
    rm data/$BIP.udp.*
  fi
  if [ -f data/$BIP.udp.oG ] \
  && [ "`cat data/$BIP.udp.oG|grep 'Status: Timeout'`" != "" ]
  then
# Nmap done at Sun Oct  5 20:27:51 2014 -- 1 IP address (1 host up) scanned in 3600.09 seconds
    echo "-$IP Removing old UDP Timeout (`cat data/$BIP.udp.oG|sed 's/.* scanned in //g'`)"
    rm data/$BIP.udp.*
  fi
  if [ -f data/$BIP.udp.oG ]
  then
    TSO=$((`date +%s`-`date -r data/$BIP.udp.oG +%s`))
    if [ $TSO -lt $((60*60*24*15)) ] # repeat after 15 days
    then
#      echo "-$IP exists as data/$BIP.udp.oG -${TSO}s old -Skipping."
      continue
    fi
    echo "-$IP exists as data/$BIP.udp.oG -${TSO}s old -Archiving old."
    DS="`date -r data/$BIP.udp.oG +%Y%m%d`"
    mkdir -p data.saved/$DS/
    mv data/$BIP.udp.* data.saved/$DS/
  fi

  R="$((`ls data/*.udp.nmap 2>>/dev/null|wc -l`))"
#  echo "[$IPSDONE/$IPSNUM $R/$MAXBG $S] Scanning $IP"
  do_scan $IP

  while :; do
    ls data/*.nmap 2>>/dev/null | \
    while read N
    do
      if [ "`cat $N 2>>/dev/null|grep '^DONE'`" != "" ]
      then
        cat $N 2>>/dev/null | grep -v '^$'
        rm $N 2>>/dev/null
#      else
#        echo "$N still running"
#        grep -H '' `echo $N|sed 's/\.nmap//g'`.* 2>>/dev/null
#        echo
      fi
    done

    LS=$S
    S=0
    R="$((`ls data/*.udp.nmap 2>>/dev/null|wc -l`))"
    if [ $R -ge $MAXBG ]
    then
      if [ $LS -ge 60 ]
      then
        S=$(($LS+60))
      else
        S=60
      fi
    fi
    if [ $R -ge $(($MAXBG*9/10)) ] \
    && [ $S == 0 ]
    then
      S=5
    fi
    if [ $R -ge $(($MAXBG*8/10)) ] \
    && [ $S == 0 ]
    then
      S=3
    fi
    if [ $R -ge $(($MAXBG*7/10)) ] \
    && [ $S == 0 ]
    then
      S=1
    fi
    if [ $S -gt 300 ]
    then
      S=300
      check_duds
    fi
#    if [ $S -gt 1 ]
#    then
#      echo "$R/$MAXBG running. Waiting $S..."
#    fi
    if [ $S -gt 0 ]
    then
      sleep $S
    fi
    R="$((`ls data/*.udp.nmap 2>>/dev/null|wc -l`))"
    if [ "$R" -lt "$MAXBG" ]
    then
      break
    fi
#    break
  done
#  break
done

#  while :; do
#    ls data/*.nmap 2>>/dev/null | \
#    while read N
#    do
#      if [ "`cat $N 2>>/dev/null|grep '^DONE'`" != "" ]
#      then
#        echo "-Done with $N"
#        cat $N 2>>/dev/null | grep -v '^$\|^DONE'
#        rm $N 2>>/dev/null
#      else
#        grep -H '' `echo $N|sed 's/\.nmap//g'`.* 2>>/dev/null | \
#        grep 'Connect Scan Timing'|tail -n1
#        sleep 1
#      fi
#    done
#    R="`ls data/*.nmap 2>>/dev/null|wc -l`"
#    if [ "$R" -gt 0 ]
#    then
#      echo "Last $R running. Waiting..."
#      sleep 300
#      continue
#    fi
#    echo "$R/$MAXBG running."
#    break
#  done

sleep 10

R="`ls data/*.tcp.nmap 2>>/dev/null|wc -l`"
echo "-Leaving $R TCP running."
R="`ls data/*.udp.nmap 2>>/dev/null|wc -l`"
echo "-Leaving $R UDP running."

echo "hia-scan-udp complete."

exit

) 2>&1 | tee -a hia-scan-udp.log

#EOF#
