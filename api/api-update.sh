#!/bin/bash

# api-update.sh
# ircerr@HypeIRC/#HIA
# 20160601
# GPLv3

# Check for needful things
cd /var/www/hia/api/ || exit 1

if [ ! -f /var/www/hia/watchlist/hia.iplist ]
then
  echo "Missing hia.iplist"
  exit 1
fi

# Generate index.json for main IPlist
IPCOUNT=0
(
echo -en "[\n"
cat /var/www/hia/watchlist/hia.iplist | \
while read IP
do
  IPCOUNT=$(($IPCOUNT+1))
  if [ $IPCOUNT -lt 2 ]
  then
    echo -en "\"$IP\""
  else
    echo -en ",\n\"$IP\""
  fi
done
echo -en "\n"
echo -en "]\n"
) > /var/www/hia/api/index.json.new
mv /var/www/hia/api/index.json.new /var/www/hia/api/index.json

# Generate /api/IPv6/index.json for each IP in IPlist
# Include relevant info per IP in json
IPCOUNT=0
cat /var/www/hia/watchlist/hia.iplist | \
sort | uniq | \
while read IP
do
  IPCOUNT=$(($IPCOUNT+1))
  IPDIR="`echo \"$IP\"|tr -d ':'`"
  mkdir -p "/var/www/hia/api/$IPDIR/"
  (
    #Start of JSON
    echo -en "{\n"
    #Nodes IPv6
    echo -en "\"IP\":\"$IP\""
    #fc00000028a71600168d43494d28ba73.tcp.oG
    #Check last scanned timestamp
    TS="";TST=0;TSU=0
    if [ -f /var/www/hia/watchlist/data/$IPDIR.tcp.oG ]
    then
      TST="`date -u -r /var/www/hia/watchlist/data/$IPDIR.tcp.oG +%s`"
    fi
    if [ -f /var/www/hia/watchlist/data/$IPDIR.udp.oG ]
    then
      TSU="`date -u -r /var/www/hia/watchlist/data/$IPDIR.udp.oG +%s`"
    fi
    if [ $TST -gt $TSU ]
    then
      TS=$TST
    fi
    if [ $TSU -gt $TST ]
    then
      TS=$TSU
    fi
#    if [ "$TS" == "" ]
#    then
#      TS="0"
#    fi
    if [ "$TS" != "" ]
    then
      echo -en ",\n\"Last_Scan\":\"$TS\""
    fi
    #IRC Nicks (TODO)
    echo -en ",\n\"IRC_Nicks\":[\"todo\",\"ircnicks\"]"
    #URL List
    echo -en ",\n\"URLs\":["
    URLCOUNT=0
    if [ "`cat /var/www/hia/watchlist/hia.urllist | sort -n | grep \"\\[$IP\\]\"`" != "" ]
    then
      cat /var/www/hia/watchlist/hia.urllist | sort -n | grep "\[$IP\]" | \
      while read URL
      do
        URLCOUNT=$(($URLCOUNT+1))
        if [ $URLCOUNT == 1 ]
        then
          echo -en "\n\"$URL\""
        else
          echo -en ",\n\"$URL\""
        fi
      done
    fi
    echo -en "\n]"
    #Shares
    echo -en ",\n\"files\":{"
    if [ -d /var/www/hia/watchlist/cifs/$IPDIR/ ] \
    || [ -d /var/www/hia/watchlist/nfs/$IPDIR/ ] \
    || [ -d /var/www/hia/watchlist/ftp/$IPDIR/ ]
    then
      FILENUM=0
      #CIFS
      if [ -d /var/www/hia/watchlist/cifs/$IPDIR/ ]
      then
        find /var/www/hia/watchlist/cifs/$IPDIR/ -name '*.files.txt' | \
        while read FILE
        do
          FILENUM=$(($FILENUM+1))
          BFILE="`basename \"$FILE\"`"
          BDISC="`echo \"$BFILE\"|sed 's/\.files.txt$//g'`"
          BURL="http://hia.cjdns.ca/watchlist/cifs/$IPDIR/$BFILE"
          if [ $FILENUM -lt 2 ]
          then
            echo -en "\n\"$BDISC\":\"$BURL\""
          else
            echo -en ",\n\"$BDISC\":\"$BURL\""
          fi
        done
      fi
      #NFS
      if [ -d /var/www/hia/watchlist/nfs/$IPDIR/ ]
      then
        find /var/www/hia/watchlist/nfs/$IPDIR/ -name '*.files.txt' | \
        while read FILE
        do
          FILENUM=$(($FILENUM+1))
          BFILE="`basename \"$FILE\"`"
          BDISC="`echo \"$BFILE\"|sed 's/\.files.txt$//g'`"
          BURL="http://hia.cjdns.ca/watchlist/nfs/$IPDIR/$BFILE"
          if [ $FILENUM -lt 2 ]
          then
            echo -en "\n\"$BDISC\":\"$BURL\""
          else
            echo -en ",\n\"$BDISC\":\"$BURL\""
          fi
        done
      fi
      #FTP
      if [ -d /var/www/hia/watchlist/ftp/$IPDIR/ ]
      then
        FILENUM=$(($FILENUM+1))
        BURL="http://hia.cjdns.ca/watchlist/ftp/"
        if [ $FILENUM -lt 2 ]
        then
          echo -en "\n\"ftp\":\"$BURL\""
        else
          echo -en ",\n\"ftp\":\"$BURL\""
        fi
      fi
    fi
    echo -en "\n}"
    echo -en ",\n\"OpenPortsTCP\":["
    #TCP Ports
    if [ -f /var/www/hia/watchlist/data/$IPDIR.tcp.oG ]
    then
      TCP_PORTS="`cat /var/www/hia/watchlist/data/$IPDIR.tcp.oG | grep ^Host | cut -d\  -f2-|grep '/open/'|sed 's/.*Ports: //g'|sed 's/\t.*//g'|tr ',' '\n'|grep '/open/'|tr '\n' ' '|sed 's/  / /g'|sed 's/ $//g'`"
#22/open/tcp//ssh/// 80/open/tcp//http/// 1337/open/tcp//waste///
      if [ "$TCP_PORTS" != "" ]
      then
#echo "TCP_PORTS:$TCP_PORTS" 1>&2
        PORTS=0
        for PORTDATA in $TCP_PORTS
        do
          PORT="`echo \"$PORTDATA\"|cut -d/ -f1`"
          PROTO="`echo \"$PORTDATA\"|cut -d/  -f3`"
#hia-parse-ver.found->fc00:0000:28a7:1600:168d:4349:4d28:ba73 22 TCP ssh OpenSSH 6.0p1 Debian 4+deb7u2 (protocol 2.0)
          SERVICE="`cat /var/www/hia/watchlist/hia-parse-ver.found|grep -i \"^$IP $PORT $PROTO \"|cut -d\  -f4`"
          if [ "$SERVICE" == "" ]
          then
            SERVICE="`echo \"$PORTDATA\"|cut -d/ -f5`"
          fi
          if [ "$SERVICE" == "" ]
          then
            SERVICE="unknown"
          fi
          PORTS=$(($PORTS+1))
          if [ $PORTS == 1 ]
          then
            echo -en "\n[$PORT,\"$SERVICE\"]"
          else
            echo -en ",\n[$PORT,\"$SERVICE\"]"
          fi
        done
      fi
    fi
    echo -en "\n]"
    #UDP Ports
    echo -en ",\n\"OpenPortsUDP\":["
    if [ -f /var/www/hia/watchlist/data/$IPDIR.udp.oG ]
    then
      UDP_PORTS="`cat /var/www/hia/watchlist/data/$IPDIR.udp.oG | grep ^Host | cut -d\  -f2-|grep '/open/'|sed 's/.*Ports: //g'|sed 's/\t.*//g'|tr ',' '\n'|grep '/open/'|tr '\n' ' '|sed 's/  / /g'|sed 's/ $//g'`"
#111/open/udp//rpcbind/// 123/open/udp//ntp///
      if [ "$UDP_PORTS" != "" ]
      then
#echo "UDP_PORTS:$UDP_PORTS" 1>&2
        PORTS=0
        for PORTDATA in $UDP_PORTS
        do
          PORT="`echo \"$PORTDATA\"|cut -d/ -f1`"
          PROTO="`echo \"$PORTDATA\"|cut -d/  -f3`"
#hia-parse-ver.found->fcc9:1eb0:6db1:07bf:59b4:a40f:bf71:158d 111 UDP rpcbind (rpcbind V2-4) 2-4 (rpc #100000)
          SERVICE="`cat /var/www/hia/watchlist/hia-parse-ver.found|grep -i \"^$IP $PORT $PROTO \"|cut -d\  -f4`"
          if [ "$SERVICE" == "" ]
          then
            SERVICE="`echo \"$PORTDATA\"|cut -d/ -f5`"
          fi
          if [ "$SERVICE" == "" ]
          then
            SERVICE="unknown"
          fi
          PORTS=$(($PORTS+1))
          if [ $PORTS == 1 ]
          then
            echo -en "\n[$PORT,\"$SERVICE\"]"
          else
            echo -en ",\n[$PORT,\"$SERVICE\"]"
          fi
        done
      fi
    fi
    echo -en "\n]"
    echo -en ",\n\"Peers\":["
    PEERNUM=0
    PEERFILE="/var/www/hia/watchlist/c/walk.peers.`date +%Y%m%d`"
    if [ -f $PEERFILE ]
    then
      cat $PEERFILE | grep "$IP" | tr ' ' '\n' | grep -v "$IP" | sort | uniq | \
      while read PEER
      do
        PEERNUM=$(($PEERNUM+1))
        if [ $PEERNUM -lt 2 ]
        then
          echo -en "\n\"$PEER\""
        else
          echo -en ",\n\"$PEER\""
        fi
      done
    fi
    echo -en "\n]"
    #End of JSON
    echo -en "\n}\n" 
  ) > "/var/www/hia/api/$IPDIR/index.json.new"
  #check if useful
  if [ "`grep Last_Scan /var/www/hia/api/$IPDIR/index.json.new`" != "" ]
  then
    #Save
    mv /var/www/hia/api/$IPDIR/index.json.new /var/www/hia/api/$IPDIR/index.json
  else
    #Forget
    rm /var/www/hia/api/$IPDIR/index.json.new
    rmdir /var/www/hia/api/$IPDIR 2>>/dev/null
  fi
#break
done

exit

#EOF#
