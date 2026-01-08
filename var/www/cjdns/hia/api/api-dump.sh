#!/bin/bash

#api-dump.sh
#ircerr@EFNet
#20160531

#GPL3

# Dump all of HIA API to local fs

# Local settings
U="`whoami`@`hostname`/`basename \"$0\"`/`md5sum \"$0\"|cut -d\  -f1`"
mkdir -p api-dump
# Get main IPList
wget -6 -U "$U" \
-o api-dump/tmp.iplist.log -O api-dump/tmp.iplist \
http://api.hia.cjdns.ca/
grep -q " saved " api-dump/tmp.iplist.log || exit 1
grep -q "\"fc" api-dump/tmp.iplist || exit 1
mv api-dump/tmp.iplist api-dump/iplist.json
rm api-dump/tmp.iplist.log

#Get index.json for each IP
cat api-dump/iplist.json | grep '"fc' | cut -d\" -f2 | grep ^fc | \
sort | uniq | \
while read IP
do
  IPD="`echo \"$IP\"|tr -d ':'`"
  wget -6 -U "$U" -o api-dump/tmp.ip.log -O api-dump/tmp.ip \
  http://api.hia.cjdns.ca/$IPD/
  grep -q " saved " api-dump/tmp.ip.log || continue
  grep -q "\"IP\":\"$IP\"" api-dump/tmp.ip || continue
  mv api-dump/tmp.ip api-dump/$IPD.json
  rm api-dump/tmp.ip.log
done

rm api-dump/tmp.* 2>>/dev/null

exit

#EOF#

