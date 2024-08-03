#!/bin/bash

touch hia-parse-http-log.db

grep peers.txt /var/log/lighttpd/cjdns.ca.access.log | \
cut -d\" -f4 | grep -v '^-$' | sort | uniq | \
while read U
do
  if [ "`grep -Fx \"$U\" hia-parse-http-log.db`" != "" ]
  then
    continue
  fi
  echo "hia-parse-http-log $U" >> /tmp/hialog.txt
  echo "$U"
  echo "$U" >> hia-parse-http-log.db
done

