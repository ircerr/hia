#!/bin/bash

#hia-parse-ftp.sh

#Check and index anonymous ftp servers
#TODO: find method of doing full ftp file listings without overloading ftpd
# and retrying on error until complete

function check_ftp() {
  IP="$1"
  PORT="$2"
  cat <<EOF > hia-parse-ftp.tmp.lftp
debug -o hia-parse-ftp.tmp.debug 9
set ssl:check-hostname 0
open $IP
user anonymous anonymous@locahost
cd /
ls -a
exit
EOF
#set ftp:ssl-allow 0
#find
#set ftp:list-options -a
  echo -n > hia-parse-ftp.tmp.err
  echo -n > hia-parse-ftp.tmp.log
  lftp -f hia-parse-ftp.tmp.lftp 2>> hia-parse-ftp.tmp.err 1>> hia-parse-ftp.tmp.log
}

#Sanity check
cd /var/www/hia/watchlist/ || exit 1

#Main
(
touch hia-parse-ftp.tried

(
cat hia.portlist | grep '\]:21 TCP$' | \
sed 's/^\[//g' | sed 's/\]:/ /g' | sed 's/ TCP$//g'
cat hia-parse-ver.found | grep -i ftp | cut -d\  -f-2
) | sort -n | uniq > hia-parse-ftp.hosts

cat hia-parse-ftp.hosts | \
while read IP PORT
do
  if [ "`grep \"^$IP $PORT \" hia-parse-ftp.tried`" != "" ]
  then
    continue
  fi
  DIR="ftp/`echo $IP|tr -d ':'`"
  if [ -d $DIR ]
  then
    continue
  fi
  nc6 -t10 -w2 -n -v -z -6 $IP $PORT 2>&1 | grep -q open$ || continue
  echo "-Trying $IP $PORT"
  check_ftp $IP $PORT
#<--- 550 SSL/TLS required on the control channel
#<--- 550 /bin/ls: Resource temporarily unavailable.
  R="`cat hia-parse-ftp.tmp.debug|grep '<--- 550 '|head -n1|sed 's/<--- //g'`"
  if [ "$R" != "" ]
  then
    rm hia-parse-ftp.tmp.*
    echo "--$R"
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-ftp [$IP]:$PORT $R" >> /tmp/hialog.txt
    fi
    if [ "`echo $R|grep 'Resource temporarily unavailable'`" == "" ]
    then
      echo "$IP $PORT $R" >> hia-parse-ftp.tried
    fi
    continue
  fi
#<--- 530 Login incorrect.
  R="`cat hia-parse-ftp.tmp.debug|grep '<--- 530 '|head -n1|sed 's/<--- //g'`"
  if [ "$R" != "" ]
  then
    rm hia-parse-ftp.tmp.*
    echo "--$R"
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-ftp [$IP]:$PORT $R" >> /tmp/hialog.txt
    fi
    echo "$IP $PORT $R" >> hia-parse-ftp.tried
    continue
  fi
  if [ "`cat hia-parse-ftp.tmp.err|grep -v '^$'`" != "" ]
  then
    echo "--Has err"
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-ftp [$IP]:$PORT UNKNOWN ERROR" >> /tmp/hialog.txt
    fi
    mkdir -p "$DIR.error"
    mv hia-parse-ftp.tmp* "$DIR.error/"
    continue
  fi
  if [ "`cat hia-parse-ftp.tmp.log|grep -v '^$'`" == "" ]
  then
    echo "--No log"
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-ftp [$IP]:$PORT ERROR NO LOG" >> /tmp/hialog.txt
    fi
    mkdir -p "$DIR.nolog"
    mv hia-parse-ftp.tmp* "$DIR.nolog/"
    continue
  fi
#<--- 230 Login successful.
#<--- 230 Guest login ok, access restrictions apply.
  R="`cat hia-parse-ftp.tmp.debug|grep '<--- 230 '|head -n1|sed 's/<--- //g'`"
  if [ "$R" != "" ]
  then
    echo "--$R"
    if [ -f /tmp/hialog.txt ]
    then
      echo "hia-parse-ftp [$IP]:$PORT $R" >> /tmp/hialog.txt
    fi
    echo "--Found $((`cat hia-parse-ftp.tmp.log|wc -l`)) files."
    echo "$IP $PORT $R" >> hia-parse-ftp.tried
    mkdir -p "$DIR"
    mv hia-parse-ftp.tmp* "$DIR/"
    continue
  fi
  if [ -f /tmp/hialog.txt ]
  then
    echo "hia-parse-ftp [$IP]:$PORT DONNO" >> /tmp/hialog.txt
  fi
  mkdir -p "$DIR.donno"
  mv hia-parse-ftp.tmp* "$DIR.dunno"
done

rm hia-parse-ftp.hosts

(
cd ftp || exit 1
(
echo -en "<html>\n"
echo -en "<head>Hyperboria Intelligence Agency - FTP</head>\n"
echo -en "<body>\n"
echo -en "<pre>\n"
echo -en "<b>Hyperboria Intelligence Agency</b> - Services for the Meshes - <i>ftp</i>\n"
echo -en "This list contains all known public FTP shares within the meshnet.\n"
echo -en "\n"
find . -mindepth 2 -type f -name 'hia-parse-ftp.tmp.log' | cut -b 3- | \
while read X
do
  echo -en "# <a href=\"$X\">$X</a>\n"
  cat $X
  echo -en "\n"
done
echo -en "</pre></body></html>\n"
) > index.html
)
) 2>&1 | tee -a hia-parse-ftp.log


