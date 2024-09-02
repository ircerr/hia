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
  PID="`ps axw|grep -v grep|grep $BIP.tcp|cut -b -6|tr -d ' '`"
  PING="`ping6 -c 5 -i .5 -w 30 $IP 2>&1 | grep 'bytes from'`"
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
#        echo "do_scan tcp - ERR no PONG ($PING) from PID:$PID for IP:$IP" >> /tmp/hialog.txt
#      fi
      kill $PID &>/dev/null
#      rm data/$BIP.tcp* &>/dev/null
      return
    fi
    echo "do_scan - ERR nmap running (`ps axw|grep -v grep|grep $BIP`)"
    return
  fi
  if [ "$PING" == "" ]
  then
    return
  fi
  if [ -f data/$BIP.tcp.nmap ]
  then
    echo "do_scan - ERR file data/$BIP.tcp.nmap exists"
    return
  fi
  echo -n > data/$BIP.tcp.nmap
 (
  nmap -PN -v -6 --allports -p1-65535 $IP -sT -r -n --host-timeout $((60*60*24*7))s \
  $PORTSCMD -oG data/$BIP.tcp.oG &> data/$BIP.tcp.log
  PING="`ping6 -c 5 -i .5 -w 10 $IP 2>&1 | grep 'bytes from'`"
  if [ "$PING" == "" ]
  then
    PING="`do_ping $IP`"
  fi
  if [ "$PING" == "" ]
  then
    echo "do_scan - ERR $IP is is DOWN"
    rm data/$BIP.tcp.*
#    if [ -f /tmp/hialog.txt ]
#    then
#      echo "ERR [$IP] TCP Fail (Host no longer UP)" >> /tmp/hialog.txt
#    fi
    return
  fi
  if [ "`cat data/$BIP.tcp.oG|grep '^# Nmap done'`" == "" ]
  then
    echo "DONE $IP TCP [nmap fail]" >>data/$BIP.tcp.nmap
    rm data/$BIP.tcp.nmap
    if [ -f /tmp/hialog.txt ]
    then
      echo "ERR [$IP] TCP Fail" >> /tmp/hialog.txt
    fi
    return
  fi
  if [ "`cat data/$BIP.tcp.oG|grep '^# Nmap done at .* (0 hosts up) scanned'`" != "" ]
  then
    echo "DONE $IP TCP [host down]"  >> data/$BIP.tcp.nmap
    rm data/$BIP.tcp.nmap
    rm data/$BIP.tcp.log data/$BIP.tcp.oG
    return
  fi
  H="`cat data/$BIP.tcp.oG | grep ^Host | cut -d\  -f2-|grep '/open/'`"
  if [ "$H" == "" ]
  then
    echo "DONE $IP TCP [no open ports]" >> data/$BIP.tcp.nmap
#    rm data/$BIP.tcp.log data/$BIP.tcp.oG
    return
  fi
#  echo "H:$H" >> data/$BIP.tcp.nmap
  PORTS="`echo $H|sed 's/.*Ports: //g'|tr ',' '\n'|grep '/open/'|cut -d\/ -f1|tr '\n' ' '|sed 's/  / /g'|sed 's/ $//g'`"
#  echo "PORTS:$PORTS" >> data/$BIP.tcp.nmap
  for PORT in $PORTS
  do
    if [ "`cat hia.portlist|grep -x \"\[$IP\]:$PORT TCP\"`" == "" ]
    then
      echo "[$IP]:$PORT TCP" >> hia.portlist
      if [ -f /tmp/hialog.txt ]
      then
        echo "hia-scan-tcp [$IP]:$PORT TCP OPEN" >> /tmp/hialog.txt
      fi
    fi
#    if [ "$PORT" == "21" ] || [ "$PORT" == "22" ] \
#    || [ "$PORT" == "25" ] || [ "$PORT" == "53" ]
#    then
#      continue
#    fi
  done
  echo "DONE $IP TCP [`echo $H|sed 's/.*Ports: //g'|tr ',' '\n'|grep '/open/'|cut -d\/ -f1|wc -l` open ports]" >>data/$BIP.tcp.nmap
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
echo "hia-scan-tcp begins."

MAXBG=30

touch hia.iplist
touch hia.portlist
touch hia.urllist

mkdir -p data/

R="`ls data/*.tcp.nmap 2>>/dev/null|wc -l`"
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
  PID="`ps axw|grep -v grep|grep $BIP.tcp|cut -b -6|tr -d ' '`"
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
#        echo "tcp - ERR no PONG ($PING) from PID:$PID for IP:$IP" >> /tmp/hialog.txt
#      fi
      kill $PID &>/dev/null
#      rm data/$BIP.tcp* &>/dev/null
      continue
    fi
#    echo "tcp - ERR nmap running (`ps axw|grep -v grep|grep $BIP`)"
    continue
  fi
  if [ "$PING" == "" ]
  then
#    echo "-$IP No PONG"
    continue
  fi
  if [ -f data/$BIP.tcp.nmap ]
  then
    echo "-$IP busy - file data/$BIP.tcp.nmap exists"
    continue
  fi
  if [ "`ps axw|grep -v grep|grep $BIP.tcp`" != "" ]
  then
#    echo "-$IP busy - nmap running (`ps axw|grep -v grep|grep $BIP`)"
    continue
  fi
  if [ -f data/$BIP.tcp.oG ] \
  && [ "`cat data/$BIP.tcp.oG|grep '^# Nmap done'`" == "" ]
  then
    echo "-$IP Removing old TCP FAIL"
    rm data/$BIP.tcp.*
  fi
  if [ -f data/$BIP.tcp.oG ] \
  && [ "`cat data/$BIP.tcp.oG|grep '^# Nmap done at .* (0 hosts up) scanned'`" != "" ]
  then
    echo "-$IP Removing old TCP DOWN"
    rm data/$BIP.tcp.*
  fi
  if [ -f data/$BIP.tcp.oG ] \
  && [ "`cat data/$BIP.tcp.oG|grep 'Status: Timeout'`" != "" ]
  then
# Nmap done at Sun Oct  5 20:27:51 2014 -- 1 IP address (1 host up) scanned in 3600.09 seconds
    echo "-$IP Removing old TCP Timeout (`cat data/$BIP.tcp.oG|sed 's/.* scanned in //g'`)"
    rm data/$BIP.tcp.*
  fi
  if [ -f data/$BIP.tcp.oG ]
  then
    TSO=$((`date -u +%s`-`date -u -r data/$BIP.tcp.oG +%s`))
    if [ $TSO -lt $((60*60*24*7)) ] # repeat after 7 days
    then
#      echo "-$IP exists as data/$BIP.tcp.oG -${TSO}s old -Skipping."
      continue
    fi
    echo "-$IP exists as data/$BIP.tcp.oG -${TSO}s old -Archiving old."
    DS="`date -u -r data/$BIP.tcp.oG +%Y%m%d`"
    mkdir -p data.saved/$DS/
    mv data/$BIP.tcp.* data.saved/$DS/
  fi

  R="$((`ls data/*.tcp.nmap 2>>/dev/null|wc -l`))"
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
    R="$((`ls data/*.tcp.nmap 2>>/dev/null|wc -l`))"
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
    R="$((`ls data/*.tcp.nmap 2>>/dev/null|wc -l`))"
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

echo "hia-scan-tcp complete."

exit

) 2>&1 | tee -a hia-scan-tcp.log

#EOF#
