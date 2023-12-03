#!/bin/bash

# Script to create and maintain *.db.cjdns.ca entries

#PUBKEY.k.db.cjdns.ca:
# host 2v6dt6f841hzhq2wsqwt263w2dswkt6fz82vcyxqptk88mtp8y50.k.db.cjdns.ca
#2v6dt6f841hzhq2wsqwt263w2dswkt6fz82vcyxqptk88mtp8y50.k.db.cjdns.ca has IPv6 address fcf4:e309:14b5:5498:cafd:4f59:4b9c:7f84
# host -t txt 2v6dt6f841hzhq2wsqwt263w2dswkt6fz82vcyxqptk88mtp8y50.k.db.cjdns.ca
#2v6dt6f841hzhq2wsqwt263w2dswkt6fz82vcyxqptk88mtp8y50.k.db.cjdns.ca descriptive text "VERSION" "v18"

# /etc/bind/named.conf.local
#include "/etc/bind/named.conf.cjdns";

# /etc/bind/named.conf.cjdns
#zone "k.db.cjdns.ca" {
#        type master;
#        notify 0;
#        file "/etc/bind/db.k.db.cjdns.ca";
#};

# /etc/bind/db.k.db.cjdns.ca
#$ORIGIN k.db.cjdns.ca.
#$TTL 86400
#@       IN      SOA     ns1.cjdns.ca. root.cjdns.ca. (
#                        2016120501 ; Serial
#                        10800           ; Refresh
#                        3600            ; Retry
#                        604800          ; Expire
#                        10800 )         ; Negative Cache TTL
#                        IN      NS      ns1.cjdns.ca.
#
#@                                       IN      AAAA            fcf4:e309:14b5:5498:cafd:4f59:4b9c:7f84
#2v6dt6f841hzhq2wsqwt263w2dswkt6fz82vcyxqptk88mtp8y50 IN AAAA fcf4:e309:14b5:5498:cafd:4f59:4b9c:7f84
#2v6dt6f841hzhq2wsqwt263w2dswkt6fz82vcyxqptk88mtp8y50 IN TXT VERSION v18

# grep 'fcf4:e309' c/walk.pubkey 
#2v6dt6f841hzhq2wsqwt263w2dswkt6fz82vcyxqptk88mtp8y50 IN AAAA fcf4:e309:14b5:5498:cafd:4f59:4b9c:7f84

# grep 2v6dt6f841hzhq2wsqwt263w2dswkt6fz82vcyxqptk88mtp8y50 c/walk.version 
#v18.2v6dt6f841hzhq2wsqwt263w2dswkt6fz82vcyxqptk88mtp8y50

(
echo -n > pubk.new
cat c/walk.pubkey | \
while read PUBK IP
do
#  echo "PUBK:$PUBK IP:$IP"
  AAAAL="`grep \"$PUBK IN AAAA $IP$\" /etc/bind/db.k.db.cjdns.ca`"
  if [ "$AAAAL" == "" ]
  then
    echo -en "$PUBK IN AAAA $IP\n" >> pubk.new
  fi
  VER="`grep \"$PUBK\" c/walk.version|cut -d\. -f1|grep ^v`"
  if [ "$VER" != "" ]
  then
    VERL="`grep \"$PUBK IN TXT VERSION\" /etc/bind/db.k.db.cjdns.ca`"
    if [ "$VERL" != "" ]
    then
      if [ "$VERL" != "$PUBK IN TXT VERSION $VER" ]
      then
        sed -i "s/$VERL/$PUBK IN TXT VERSION $VER/g" /etc/bind/db.k.db.cjdns.ca
      fi
    else
      echo -en "$PUBK IN TXT VERSION $VER\n" >> pubk.new
    fi
#  else
#    echo -en "$PUBK IN TXT VERSION 0\n" >> pubk.new
  fi
done

echo "-Adding `wc -l pubk.new|cut -d\  -f1`"
if [ "`head -n5 pubk.new`" != "" ]
then
#/etc/bind/db.k.db.cjdns.ca:                     2016112701      ; Serial
  ST="`cat /etc/bind/db.k.db.cjdns.ca|grep 'Serial$'|tr -d ' \|\t'|cut -d\; -f1|cut -b -8`"
  DS="`date -u +%Y%m%d`"
  if [ "$ST" == "$DS" ]
  then
    SI="`cat /etc/bind/db.k.db.cjdns.ca|grep 'Serial$'|tr -d ' \|\t'|cut -d\; -f1|cut -b 9-|sed 's/^0//g'`"
  else
    SI="0"
  fi
  SI=$(($SI+1))
  if [ ${#SI} -lt 2 ]; then SI="0$SI"; fi
  echo "-ST:\"$ST\" DS:\"$DS\" SI:\"$SI\""
  sed -i "s/[0-9][0-9][0-9][0-9].*; Serial$/$DS$SI ; Serial/g" /etc/bind/db.k.db.cjdns.ca
  cat pubk.new >> /etc/bind/db.k.db.cjdns.ca
  service bind9 reload
fi
tail -n5 pubk.new
rm pubk.new

) 2>&1 | tee pubk.log

# EOF #
