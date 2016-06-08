#!/bin/bash

(
touch hia-parse-nfs.db

if [ ! -d nfs/ ]
then
  mkdir -p nfs/
fi

#fix bad unmounts
mount | grep -q nfs4 && umount -a -f -t nfs4 && sleep 1
mount | grep -q nfs4 && umount -a -l -t nfs4 && sleep 1
mount | grep -q nfs && umount -a -f -t nfs && sleep 1
mount | grep -q nfs && umount -a -l -t nfs && sleep 1

echo "-NFS begins"
#cat hia-parse-ver.found | grep -i nfs | cut -d\  -f1 | sort | uniq | \
cat hia.portlist | grep '\]:2049 ' | \
cut -d\[ -f2 | cut -d\] -f1 | sort -n | uniq | \
while read IP
do
  IPL="nfs/`echo $IP|tr -d ':'`"
  if [ -d $IPL ]
  then
##    echo "$IP (Skip/exists)"
    continue
  fi
  if [ "`grep \"^$IP \" hia-parse-nfs.db`" != "" ]
  then
    continue
  fi
#  ping6 -c 3 -w 5 -i .5 $IP 2>&1 | grep -q icmp_seq || continue
  if [ "`nc6 -nvz -t30 -w30 $IP 2049 2>&1 | grep open`" == "" ] \
  && [ "`nc6 -nvuz -t30 -w30 $IP 2049 2>&1 | grep open`" == "" ]
  then
    continue
  fi
#  echo "-Trying $IP"
  showmount -e $IP 2>&1 | tee hia-parse-nfs.tmp
#clnt_create: RPC: Program not registered
  if [ "`cat hia-parse-nfs.tmp|grep 'Program not registered'`" != "" ]
  then
    echo "-ERR for $IP"
    continue
  fi
#clnt_create: RPC: Timed out
  if [ "`cat hia-parse-nfs.tmp|grep 'Timed out'`" != "" ]
  then
    echo "-Timed out for $IP"
    continue
  fi
#clnt_create: RPC: Port mapper failure - Unable to receive: errno 111 (Connection refused)
  if [ "`cat hia-parse-nfs.tmp|grep 'Connection refused'`" != "" ]
  then
    echo "-Refused for $IP"
    continue
  fi
#clnt_create: RPC: Authentication error
  if [ "`cat hia-parse-nfs.tmp|grep 'Authentication error'`" != "" ]
  then
    echo "-Auth Error for $IP"
    continue
  fi
#Export list for fc3f:c58c:623c:44f9:6af0:50d7:f47b:2985:
#/home/nfs 192.168.10.0/255.255.255.0
#/mnt/x    192.168.10.0/255.255.255.0
#/mnt/z    192.168.10.0/255.255.0.0
  if [ "`cat hia-parse-nfs.tmp|grep 'Export list for'`" != "" ]
  then
    mkdir -p "$IPL"
    mv hia-parse-nfs.tmp "$IPL/showmounts.txt"
    cat "$IPL/showmounts.txt" | grep -v 'Export list for '| \
    while read L
    do
      NFSD="`echo \"$L\"|cut -d\  -f1`"
      NFSP="`echo \"$L\"|cut -d\  -f2-|tr -d ' '`"
      echo "NFSD:$NFSD NFSP:$NFSP"
      echo "hia-parse-nfs [$IP] $NFSD ($NFSP)" >> /tmp/hialog.txt
##########
      if [ "$NFSP" != "*" ] \
      && [ "`echo $NFSP|grep -i 'everyone'`" == "" ]
      then
        echo "-No permission ($NFSP)"
        continue
      fi
      NFSB="`basename \"$NFSD\"`"
      mkdir -p "$IPL/$NFSB"
      chmod og-rwx "$IPL/$NFSB"
      if [ -f "$IPL/$NFSB.nfo" ]
      then
        continue
      fi
      echo "-Mounting [$IP]:$NFSD"
      mount -v -t nfs "[$IP]:$NFSD" "$IPL/$NFSB" 2>&1 | \
      tee "$IPL/$NFSB.nfo" || rmdir "$IPL/$NFSB"
#[fc96:c182:d2b6:83a5:ccac:2de3:2abf:ce9e]:/datastore on /home/cjdns/www/watchlist/nfs type nfs (rw,relatime,vers=3,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp6,timeo=600,retrans=2,sec=sys,mountaddr=fc96:c182:d2b6:83a5:ccac:2de3:2abf:ce9e,mountvers=3,mountport=47960,mountproto=udp6,local_lock=none,addr=fc96:c182:d2b6:83a5:ccac:2de3:2abf:ce9e)
# df -h nfs/
#Filesystem                                            Size  Used Avail Use% Mounted on
#[fc96:c182:d2b6:83a5:ccac:2de3:2abf:ce9e]:/datastore  2.7T  2.6T  146G  95% /home/cjdns/www/watchlist/nfs
#mount.nfs: access denied by server while mounting [fc4c:6906:317e:d158:015e:e0f5:21be:e382]:/mnt/storage
      if [ "`cat \"$IPL/$NFSB.nfo\"|grep 'access denied by server'`" != "" ]
      then
        echo "-DENIED for [$IP]:$NFSD"
        echo "hia-parse-nfs [$IP]:$NFSD mount denied." >> /tmp/hialog.txt
        rmdir "$IPL/$NFSB" 2>>/dev/null
        continue
      fi
      if [ ! -d "$IPL/$NFSB" ] \
      && [ "`mount | grep \"$IPL/$NFSB\"`" == "" ]
      then
        echo "-FAIL for [$IP]:$NFSD"
        echo "hia-parse-nfs [$IP]:$NFSD mount failed." >> /tmp/hialog.txt
        rm "$IPL/$NFSB.nfo"
        rmdir "$IPL/$FSB" "$IPL" 2>>/dev/null
        continue
      fi
      echo "-Dumping mount info"
      mount | grep "$IPL/$NFSB" >> "$IPL/$NFSB.nfo"
      df -h | grep "$IPL/$NFSB" >> "$IPL/$NFSB.nfo"
      echo "-Dumping files list"
      find "$IPL/$NFSB" -type f &> "$IPL/$NFSB.files.txt"
      FILES="`wc -l \"$IPL/$NFSB.files.txt\"|cut -d\  -f1`"
      echo "-Found $FILES files."
      echo "hia-parse-nfs [$IP]:$NFSD found $FILES files." >> /tmp/hialog.txt
      sync
      echo "-Unmounting $IP/$NFSB"
      umount "$IPL/$NFSB" || umount -f "$IPL/$NFSB"
      rmdir "$IPL/$NFSB"
      rmdir "$IPL" 2>>/dev/null
    done
    continue
  fi
#  cat hia-parse-nfs.tmp >> /tmp/hialog.txt
  echo "-UNKNOWN for $IP"
  break
done

#fix bad unmounts
mount | grep -q nfs4 && umount -a -f -t nfs4 && sleep 1
mount | grep -q nfs4 && umount -a -l -t nfs4 && sleep 1
mount | grep -q nfs && umount -a -f -t nfs && sleep 1
mount | grep -q nfs && umount -a -l -t nfs && sleep 1

echo "-NFS complete"

#rebuild index
(
cd nfs || exit 1
(
  echo -en "<html>\n"
  echo -en "<head>Hyperboria Intelligence Agency - NFS</head>\n"
  echo -en "<body>\n"
  echo -en "<pre>\n"
  echo -en "<b>Hyperboria Intelligence Agency</b> - Services for the Meshes - <i>nfs</i>\n"
  echo -en "This list contains all known public NFS shares within the meshnet.\n"
  echo -en "\n"

  find . -mindepth 2 -type f -name '*.files.txt' | cut -b 3- | \
  while read X
  do
    echo -en "<a href=\"$X\">$X</a>\n";
  done
  echo -en "</pre></body></html>\n"
) > index.html.new
mv index.html.new index.html
cd ..
)

) 2>&1 | tee -a hia-parse-nfs.log

exit


