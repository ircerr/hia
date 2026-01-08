#!/bin/bash

cd /var/www/cjdns/hia/watchlist/ || exit 1

(
TS="`date -u +%Y%m%d`"
LIVE_NODES="`cat walk/walk.peers.$TS | tr ' ' '\n' | sort | uniq | wc -l`"
CRAWL_NODES="`cat walk/tmp/walk.paths.todo walk/tmp/walk.paths.done walk/tmp/walk.paths.errors | sort | uniq | wc -l`"
KNOWN_IPS="`cat hia.iplist.all | wc -l`"
KNOWN_KEYS="`cat walk/walk.pubkey | wc -l`"
KNOWN_PORTS="`cat hia.portlist | cut -d\] -f2- | cut -d: -f2-|wc -l`"
KNOWN_PORTS_TCP="`cat hia.portlist | grep TCP$ | cut -d\] -f2- | cut -d: -f2-|wc -l`"
KNOWN_PORTS_UDP="`cat hia.portlist | grep UDP$ | cut -d\] -f2- | cut -d: -f2-|wc -l`"
KNOWN_SCANS="`ls data/*.oG 2>>/dev/null|sed 's/.tcp.oG//g;s/.udp.oG//g'|sort|uniq|wc -l`"
KNOWN_SCANS_UDP="`ls data/*.udp.oG 2>>/dev/null|wc -l`"
KNOWN_SCANS_TCP="`ls data/*.tcp.oG 2>>/dev/null|wc -l`"
LIVE_IPS="`cat hia.iplist | wc -l`"
LIVE_SCANS="`ls data/*.nmap 2>>/dev/null|sed 's/.tcp.nmap//g;s/.udp.nmap//g'|sort|uniq|wc -l`"
LIVE_SCANS_UDP="`ls data/*.udp.nmap 2>>/dev/null|wc -l`"
LIVE_SCANS_TCP="`ls data/*.tcp.nmap 2>>/dev/null|wc -l`"
CURRENT_SCANS="`cat hia.iplist|tr -d ':'>hia-stats.tmp.x;ls data/*.nmap 2>>/dev/null|cut -d\. -f1|sort|uniq|grep -f hia-stats.tmp.x|wc -l; rm hia-stats.tmp.x`"
CURRENT_SCANS_UDP="`cat hia.iplist|tr -d ':'>hia-stats.tmp.x;ls data/*.udp.nmap 2>>/dev/null|cut -d\. -f1|sort|uniq|grep -f hia-stats.tmp.x|wc -l; rm hia-stats.tmp.x`"
CURRENT_SCANS_TCP="`cat hia.iplist|tr -d ':'>hia-stats.tmp.x;ls data/*.tcp.nmap 2>>/dev/null|cut -d\. -f1|sort|uniq|grep -f hia-stats.tmp.x|wc -l; rm hia-stats.tmp.x`"
SCAN_DONE_ALL=$(($KNOWN_SCANS-$LIVE_SCANS))
SCAN_DONE=$(($LIVE_IPS-$CURRENT_SCANS))
LA="`uptime|sed 's/.*load average: //g;s/, .*//g'`"
#PER_DONE=$(($SCAN_DONE*100/$KNOWN_IPS))
#PER_DONE="`echo \"scale=2; $SCAN_DONE_ALL*100/$KNOWN_IPS\"|bc`"
PER_DONE="`echo \"scale=2; $SCAN_DONE*100/$LIVE_IPS\"|bc`"
#PORTS_TCP="`cat hia-scan-tcp.portlist|wc -l`"
#PORTS_UDP="`cat hia-scan-tcp.portlist|wc -l`"
if [ "`echo \"$PER_DONE\"|cut -b1`" == "." ]
then
  PER_DONE="0$PER_DONE"
fi
echo -n "CrawlNodes:$CRAWL_NODES KnownKeys:$KNOWN_KEYS"
echo -n " KnownIPs:$KNOWN_IPS ScannedIPs:$SCAN_DONE_ALL (all) $SCAN_DONE (done)"
echo -n " KnownPorts:$KNOWN_PORTS (TCP:$KNOWN_PORTS_TCP/UDP:$KNOWN_PORTS_UDP)"
echo -n " KnownScans:$KNOWN_SCANS ($KNOWN_SCANS_TCP TCP/$KNOWN_SCANS_UDP UDP)"
echo -n " LiveNodes:$LIVE_NODES LiveIPs:$LIVE_IPS"
echo -n " LiveScans:$LIVE_SCANS ($LIVE_SCANS_TCP TCP/$LIVE_SCANS_UDP UDP)"
echo " Complete:$PER_DONE% Load:$LA"
if [ -f /tmp/hialog.txt ]
then
(
  echo -n "hia-stats CrawlNodes:$CRAWL_NODES KnownKeys:$KNOWN_KEYS"
  echo -n " KnownIPs:$KNOWN_IPS ScannedIPs:$SCAN_DONE_ALL (all) $SCAN_DONE (done)"
  echo -n " KnownPorts:$KNOWN_PORTS (TCP:$KNOWN_PORTS_TCP/UDP:$KNOWN_PORTS_UDP)"
  echo -n " KnownScans:$KNOWN_SCANS ($KNOWN_SCANS_TCP TCP/$KNOWN_SCANS_UDP UDP)"
  echo -n " LiveNodes:$LIVE_NODES LiveIPs:$LIVE_IPS"
  echo -n " LiveScans:$LIVE_SCANS ($LIVE_SCANS_TCP TCP/$LIVE_SCANS_UDP UDP)"
  echo " Complete:$PER_DONE% Load:$LA"
) >> /tmp/hialog.txt
fi
) 2>&1 | tee -a hia-parse-stats.log



#Check found open ports vs versions detected on them
# echo "PORTNUM PORTCOUNT VERCOUNT SERVICES"; cat yia-scan-*.portlist|cut -d\] -f2-|cut -d: -f2|cut -d\  -f1|sort -n|uniq|while read P; do VC="`cat yia-parse-ver.found|cut -d\  -f2|grep -x $P|wc -l`"; PC="`cat yia-scan-*.portlist|cut -d\] -f2|cut -d: -f2|cut -d\  -f1|grep -x $P|wc -l`"; S="`cat /usr/share/nmap/nmap-services|tr '\t' ' '|grep \"$P/tcp\|$P/udp\"|cut -d\  -f1|sort|uniq|tr '\n' '|'|sed 's/|$//g'`"; if [ "$S" == "" ]; then S="notfound"; fi; if [ "$VC" -lt "1" ] && [ "$PC" -gt "10" ]; then echo "$P $PC $VC $S"; fi; done

