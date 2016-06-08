#!/bin/bash

# hia-parse-cifs.sh
# HIA CIFS Indexer

# Sanity check
cd /var/www/hia/watchlist/ || exit 1
smbclient --help &>/dev/null || exit 1

(
if [ ! -d cifs/ ]
then
  mkdir -p cifs/
fi
#fix bad unmounts
mount|grep -q cifs&&umount -a -t cifs

echo "-CIFS begins"
cat hia.portlist | grep '\]:139 \|\]:443 ' | \
cut -d\[ -f2 | cut -d\] -f1 | sort -n | uniq | \
while read IP
do
  IPL="cifs/`echo $IP|tr -d ':'`"
  if [ -d $IPL ]
  then
##    echo "$IP (Skip/exists)"
    continue
  fi
#  echo -n "$IP "
  mkdir -p $IPL
  smbclient -U anonymous -N -L//$IP &>$IPL/hia-parse-cifs.log
  if [ "`cat $IPL/hia-parse-cifs.log|grep '^Connection to .* failed\|^protocol negotiation failed'`" != "" ]
  then
#    echo "-Failed"
    rm $IPL/hia-parse-cifs.log
    rmdir $IPL 2>>/dev/null
    continue
  fi
  echo "[$IP] Success?"
  cat $IPL/hia-parse-cifs.log | \
  grep -v '^$\|Anonymous login successful\|Sharename .* Type .* Comment\|fc.* is an IPv6 address\|\-\-\-\-\-\-\|print\$\|Printer' \
  > $IPL/smbclient.log
  cat $IPL/smbclient.log | \
  while read LINE
  do
    if [ ! -f /tmp/hialog.txt ]
    then
      echo "hia-parse-cifs [$IP] $LINE"
    else
      echo "hia-parse-cifs [$IP] $LINE" | tee -a /tmp/hialog.txt
    fi
  done
  echo -n > $IPL/smbclient.shares.log
  cat $IPL/smbclient.log | \
  grep 'Disk' | sed 's/ Disk  .*//g' | grep -v '^$' | \
  while read X
  do
    Y="`echo $X`"
    echo "$Y" >> $IPL/smbclient.shares.log
  done
  cat $IPL/smbclient.shares.log | \
  while read D
  do
#    break
    mkdir -p "$IPL/$D"
    if [ -f "$IPL/$D.nfo" ]
    then
      continue
    fi
    echo "-Mounting $IP/$D"
    mount -t cifs -o username='anonymous',guest "//$IP/$D" "$IPL/$D" 2>&1 | \
    tee "$IPL/$D.nfo" || rmdir "$IPL/$D"
    if [ "`cat \"$IPL/$D.nfo\"|grep 'mount error.* Permission denied'`" != "" ]
    then
      echo "-DENIED"
      if [ -f /tmp/hialog.txt ]
      then
        echo "hia-parse-cifs [$IP] mounting $D denied." >> /tmp/hialog.txt
      fi
      rmdir "$IPL/$D" "$IPL" 2>>/dev/null
      continue
    fi
    if [ ! -d "$IPL/$D" ] \
    || [ "`mount | grep -q \"$IPL/$D\"`" == "" ]
    then
      echo "-FAIL"
      if [ -f /tmp/hialog.txt ]
      then
        echo "hia-parse-cifs [$IP] mounting $D failed." >> /tmp/hialog.txt
      fi
      rm "$IPL/$D.nfo"
      rmdir "$IPL/$D" "$IPL" 2>>/dev/null
      continue
    fi
    echo "-Dumping mount info"
    mount | grep "$IPL/$D" >> "$IPL/$D.nfo"
    df -h | grep "$IPL/$D" >> "$IPL/$D.nfo"
    echo "-Dumping files list"
    find "$IPL/$D" -type f &> "$IPL/$D.file.txt"
    FILES="`wc -l \"$IPL/$D.file.txt\"|cut -d\  -f1`"
    echo "-Found $FILES files."
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-cifs [$IP] $D found $FILES files." >> /tmp/hialog.txt
    fi
    sync
    echo "-Unmounting $IP/$D"
    umount "$IPL/$D" || umount -f "$IPL/$D"
    rmdir "$IPL/$D"
    rmdir "$IPL" 2>>/dev/null
  done
done
#fix bad unmounts
mount|grep -q cifs&&umount -a -t cifs

#rebuild index
cd cifs || exit 1
(
  echo "<html><body><pre>"
  find . -mindepth 2 -type f -name 'hia-parse-ftp.tmp.log' | \
  while read X
  do
    echo "<a href=\"$X\">$X</a>\n";
  done
  echo "</pre></body></html>"
) > index.html.new
mv index.html.new index.html
cd ..

echo "-CIFS complete"
) 2>&1 | tee -a hia-parse-cifs.log
