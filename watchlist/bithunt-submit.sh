#!/bin/bash

# bithunt-submit.sh
# Submit URLs to bithunt

function urlencode() {
  echo "$1" | \
  sed 's/:/%3A/g'|sed 's/\//%2F/g'|sed 's/\[/%5B/g'|sed 's/\]/%5D/g'
}

cd /var/www/hia/watchlist/ || exit 1

(
touch bithunt.submitted

cat hia.urllist | \
sort | uniq | \
while read URL
do
  URLE="`urlencode $URL`"
  if [ "`grep -Fxi \"$URL\" bithunt.submitted`" != "" ]
  then
    continue
  fi
  echo "URL:$URL URLE:$URLE"
  echo -n > bithunt-submit.log
  echo -n > bithunt-submit.html
  echo -n > bithunt-submit.err
  wget -U "bithunt-submit.sh/0.00" \
     -d -t1 -w30 \
     --referer "http://[fc77:699b:c203:1f3f:cb18:d862:524d:5d7a]/stats/addsite" \
     "http://[fc77:699b:c203:1f3f:cb18:d862:524d:5d7a]/stats/addsite" \
     --post-data="url=$URLE" \
     -o bithunt-submit.log -O bithunt-submit.html 2>bithunt-submit.err
  if [ "`cat bithunt-submit.log|grep 'bithunt-submit.html.* saved'`" == "" ]
  then
    echo "-Failed to save result"
    break
  fi
  if [ "`cat bithunt-submit.html|grep 'bithunt has added your URL'`" == "" ]
  then
    echo "-Failed to add url"
    break
  fi
  echo "$URL" >> bithunt.submitted
  echo "-Submitted"
  rm bithunt-submit.log bithunt-submit.html bithunt-submit.err
done

) 2>&1 | tee -a bithunt-submit.log

exit

# EOF #
