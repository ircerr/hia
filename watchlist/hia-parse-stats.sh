#!/bin/bash

cd /var/www/hia/watchlist/ || exit 1

TCP_FILES="`find data/ -type f -name '*.tcp.nmap'|wc -l`"
UDP_FILES="`find data/ -type f -name '*.udp.nmap'|wc -l`"
TCP_PROCS="`ps axw|grep -v grep|grep 'nmap .*.tcp.oG'|wc -l`"
UDP_PROCS="`ps axw|grep -v grep|grep 'nmap .*.udp.oG'|wc -l`"

echo "Active NMAPs : TCP FILES:$TCP_FILES PROCS:$TCP_PROCS | UDP FILES:$UDP_FILES PROCS:$UDP_PROCS"
echo "hia-parse-stats Active NMAPs : TCP FILES:$TCP_FILES PROCS:$TCP_PROCS | UDP FILES:$UDP_FILES PROCS:$UDP_PROCS" >> /tmp/hialog.txt

