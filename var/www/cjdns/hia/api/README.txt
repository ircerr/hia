# README.txt
# HIA API README

## Usage and expected results:

# IP list
$ wget -U 'hia-api-parser' -O index.json http://api.hia.cjdns.ca/
[
"fc00:0000:0000:0000:0000:0000:0000:0000",
"fc00:0000:0000:0000:0000:0000:0000:0001",
"fc00:0000:0000:0000:0000:0000:0000:0002"
]

# IP data
#  note: format is first expanded ipv6 then all : removed
#  fcf4:e309:14b5:5498:cafd:4f59:4b9c:7f84 becomes fcf4e30914b55498cafd4f594b9c7f84
$ wget -U 'hia-api-parser' -O fcf4e30914b55498cafd4f594b9c7f84.json \
 http://api.hia.cjdns.ca/fcf4e30914b55498cafd4f594b9c7f84
{
"IP":"fcf4:e309:14b5:5498:cafd:4f59:4b9c:7f84",
"Last_Scan":"1464496529",
"IRC_Nicks":["TODO"],
"URLs":[
"http://[fcf4:e309:14b5:5498:cafd:4f59:4b9c:7f84]:80/"
],
"files":{
},
"OpenPortsTCP":[
[53,"domain"],
[80,"http"],
[111,"rpcbind"],
[113,"ident"],
[222,"ssh"],
[6667,"irc"],
[25367,"eggdrop"],
[57012,"status"]
],
"OpenPortsUDP":[
[53,"domain"],
[111,"rpcbind"],
[123,"ntp"]
],
"Peers":[
"fc13:6176:aaca:8c7f:9f55:924f:26b3:4b14",
"fc34:8675:ed95:600c:38d7:6eb8:f5b9:5bfa",
"fc72:c065:f915:838e:f158:2242:a871:c719",
"fca8:2dd7:4987:a9be:c8fc:34d7:05a1:4606",
"fcaf:887a:9497:0a8c:32d1:fa90:c959:251f",
"fcbb:5056:899e:2838:f1ad:12eb:9704:1ff1",
"fcd7:164f:b5be:7542:513b:3661:3d4f:3601",
"fcde:5b9e:fe85:5af7:5368:6dff:729d:f859"
]
}

# IP of user
http://api.hia.cjdns.ca/me/
(redirects to users info if found)


## Notes
# Usage of custom User-Agents to reflect project or usage case
#  This will help debug problems and avoid generic user agent bans due to abuse
# Note /api/ and /api/$IPD/ are identical to / and /$IPD/
#  using a simlink to . for api on the server side.
#  Consider /api/ depereciated already as its kind of redundant

## Data formatting
* Time of last scan
-reading nmap .oG files for timestamp in UTC unixtime
$ date -u -r data/fc0000000d7f200e0e9671f803abaead.tcp.oG +%s -> 1464393282
* IRC nicks associated with the IP
-- TODO - need ip nick listing --
* Http/Https links (if applicable)
-reading hia.urllist
* link to CIFS/NFS/FTP file listing (if applicable)
-check for existing dirs of cifs/$IPD nfs/$IPD ftp/$IPD
* List of open ports with port number and short description of service type
-check data/fc*.oG for last scan results (live vs hia.portlist historical)
-check hia-parse-ver.found for identified protocol
-fail back to nmap guess based on port number
* All information accessable as JSON
-via bash and creating hand crafted index.json files per dir
-marked as valid index files in lighttpd
* send header: Access-Control-Allow-Origin: *
$ wget -d -O - http://api.hia.cjdns.ca/ 2>&1|grep Access
Access-Control-Allow-Origin: *
-done via vhost settings



#EOF#

