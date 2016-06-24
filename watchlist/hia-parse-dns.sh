#!/bin/bash

# hia-parse-dns.sh
# 20141007

#dns (+done)
# +check for clearnet ipv4 host lookups
#  check for clearnet ipv4 ip lookups
# +check for clearnet ipv6 host lookups
#  check for clearnet ipv6 lookups
#  check for .h lookups
# +check for .bit lookups
#  check for .hype lookups
#  check for .onion lookups (?)
#  check for .i2p lookups  (?)
#  check rdns $IP via $IP
# +check NXDOMAIN
#  check trap domain? ngrep for 'listening.cjdns.ca'?

# fc0a:484c:ea6d:c325:dcb6:36a0:4f33:427c .bit .emc .bazar,.lib and .coin decentralized domains.
# host tx1683.emc fc0a:484c:ea6d:c325:dcb6:36a0:4f33:427c
#tx1683.emc has IPv6 address fc0a:484c:ea6d:c325:dcb6:36a0:4f33:427c
#tx1683.emc mail is handled by 5 txpi.tx1683.emc.

#Sanity checks
cd /var/www/hia/watchlist/ || exit 1

(
touch hia-parse-dns.db
touch hia.portlist

VPS_IP4="`host cjdns.ca|grep 'has address'|sed 's/.* has address //g'`"
if [ "VPS_IP4" == "" ]
then
  echo "-ERROR: Unable to resolve vps IPv4"
  exit 1
fi
VPS_IP6="`host h.cjdns.ca|grep 'has IPv6 address'|sed 's/.* has IPv6 address //g'`"
if [ "VPS_IP6" == "" ]
then
  echo "-ERROR: Unable to resolve vps IPv6"
  exit 1
fi

cat hia.portlist | grep '\]:53 ' | \
cut -d\[ -f2 | cut -d\] -f1 | sort -n | uniq | \
while read IP
do
#  if [ "`cat hia-parse-dns.tried|grep -x \"\[$IP\]\"`" != "" ]
#  then
#    continue
#  fi
  if [ "`ping6 -c 5 -i .5 -w 5 $IP 2>&1 | grep 'bytes from'`" == "" ]
  then
    continue
  fi
  nc6 -nvz -t10 -w2 $IP 53 2>&1 | grep -q 'open$' || continue
#  echo "[$IP]"
  if [ "`cat hia-parse-dns.db|grep \"^\[$IP\] ICANN A \"`" == "" ]
  then
# host cjdns.ca 127.0.0.1 2>&1 | grep ' has address '
#cjdns.ca has address 185.19.104.122
    echo -n "[$IP] ICANN A "
    R="`host cjdns.ca $IP 2>&1 | grep ' has address '|sed 's/.* has address //g'`"
    if [ "$R" != "" ]
    then
      if [ "$R" == "$VPS_IP4" ]
      then
        echo "OK"
        echo "[$IP] ICANN A OK" >> hia-parse-dns.db
        if [ -f /tmp/hialog.txt ]
        then
          echo "hia-parse-dns [$IP] ICANN A OK" >> /tmp/hialog.txt
        fi
      else
        R="`echo $R|tr '\n' ' '|sed 's/ $//g'`"
        echo "ERR($R)"
        if [ -f /tmp/hialog.txt ]
        then
          echo "[$IP] ICANN A ERR($R)" >> hia-parse-dns.db
        fi
      fi
    else
      echo "FAIL"
      echo "[$IP] ICANN A FAIL" >> hia-parse-dns.db
    fi
  fi
  if [ "`cat hia-parse-dns.db|grep \"^\[$IP\] ICANN AAAA \"`" == "" ]
  then
    echo -n "[$IP] ICANN AAAA "
    R="`host h.cjdns.ca $IP 2>&1 | grep ' has IPv6 address '|sed 's/.* has IPv6 address //g'`"
    if [ "$R" != "" ]
    then
      if [ "$R" == "$VPS_IP6" ]
      then
        echo "OK"
        echo "[$IP] ICANN AAAA OK" >> hia-parse-dns.db
        if [ -f /tmp/hialog.txt ]
        then
          echo "hia-parse-dns [$IP] ICANN AAAA OK" >> /tmp/hialog.txt
        fi
      else
        echo "ERR($R)"
        echo "[$IP] ICANN AAAA ERR($R)" >> hia-parse-dns.db
      fi
    else
      echo "FAIL"
      echo "[$IP] ICANN AAAA FAIL" >> hia-parse-dns.db
    fi
  fi
  if [ "`cat hia-parse-dns.db|grep \"^\[$IP\] ICANN NXDOMAIN \"`" == "" ]
  then
    echo -n "[$IP] ICANN NXDOMAIN "
    R="`host nxdomain.google.ca $IP 2>&1|grep ' not found.*NXDOMAIN\|has .*address'|sed 's/.*(//g'|sed 's/).*//g'|sed 's/.*has .*address //g'|sort|uniq|tr '\n' ' '|sed 's/ $//g'`"
    if [ "$R" != "" ]
    then
      if [ "$R" == "NXDOMAIN" ]
      then
        echo "OK"
        echo "[$IP] ICANN NXDOMAIN OK" >> hia-parse-dns.db
#        if [ -f /tmp/hialog.txt ]
#        then
#          echo "hia-parse-dns [$IP] ICANN NXDOMAIN OK" >> /tmp/hialog.txt
#        fi
      else
        echo "ERR($R)"
        echo "[$IP] ICANN NXDOMAIN ERR($R)" >> hia-parse-dns.db
        if [ -f /tmp/hialog.txt ]
        then
          echo "hia-parse-dns [$IP] ICANN NXDOMAIN ERR($R)" >> /tmp/hialog.txt
        fi
      fi
    else
      echo "FAIL"
      echo "[$IP] ICANN NXDOMAIN FAIL" >> hia-parse-dns.db
    fi
  fi
# http://en.wikipedia.org/wiki/Alternative_DNS_root
  if [ "`cat hia-parse-dns.db|grep \"^\[$IP\] BITTLD \"`" == "" ]
  then
# host dotbitwhois.bit
#Host dotbitwhois.bit not found: 3(NXDOMAIN)
#dotbitwhois.bit has address 198.105.244.228
#dotbitwhois.bit has address 198.105.254.228
    echo -n "[$IP] BITTLD "
    R="`host dotbitwhois.bit $IP 2>&1 | grep ' has.* address '|sed 's/.* address //g'|sort -n|tr '\n' ' '|sed 's/ $//g'`"
    if [ "$R" != "" ]
    then
      if [ "$R" == "192.185.225.13" ]
      then
        echo "OK"
        echo "[$IP] BITTLD OK" >> hia-parse-dns.db
        if [ -f /tmp/hialog.txt ]
        then
          echo "hia-parse-dns [$IP] BITTLD OK" >> /tmp/hialog.txt
        fi
      else
        echo "ERR($R)"
        echo "[$IP] BITTLD ERR($R)" >> hia-parse-dns.db
      fi
    else
      echo "FAIL"
      echo "[$IP] BITTLD FAIL" >> hia-parse-dns.db
    fi
  fi
#  if [ "`cat hia-parse-dns.tried|grep -Fx \"\[$IP\]\"`" == "" ]
#  then
#    echo "[$IP]" >> hia-parse-dns.tried
#  fi
  sleep .1 || break
done

#TODO#
# nodeinfo.hype has IPv6 address fc5d:baa5:61fc:6ffd:9554:67f0:e290:7535
# sql-ca.btc has IPv6 address fc38:4c2c:1a8f:3981:f2e7:c2b9:6870:6e84
# uppit.nxt 

exit

) 2>&1 | tee -a hia-parse-dns.log

# EOF #
