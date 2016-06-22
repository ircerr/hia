#!/bin/bash

while :; do
  cd /var/www/hia/watchlist/ || exit 1
  if [ ! -x l.sh ]; then break; fi
  ./hia-iplist.sh
  ./hia-scan-tcp.sh
  ./hia-scan-udp.sh
  ./hia-parse.sh
  cd /var/www/hia/api/ || exit 1
  ./api-update.sh
  echo "-Sleeping..."
  sleep $((60*10)) || break
  echo
done

# EOF #
