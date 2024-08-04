#!/bin/bash

touch hia-parse-http-referer.db

grep peers.txt \
/var/log/lighttpd/cjdns.ca.access.log \
/var/log/lighttpd/hia.cjdns.ca.access.log | \
cut -d\" -f4 | grep -v '^-$' | sort | uniq | \
while read U
do
  if [ "`grep -Fx \"$U\" hia-parse-http-referer.db`" != "" ]
  then
    continue
  fi
  echo "hia-parse-http-referer $U" >> /tmp/hialog.txt
  echo "$U"
  echo "$U" >> hia-parse-http-referer.db
done

