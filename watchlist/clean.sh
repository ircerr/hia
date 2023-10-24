#!/bin/bash

if [ ! -d data.saved/ ]
then
  echo "----WHERE AM I? (`pwd` not has data.saved/)"
  exit 1
fi

USED=$(("`df . --output=pcent|tr -d ' \|%'|grep -v '^[A-Z]'`"))
if [ "$USED" -lt 80 ]
then
  exit 0
fi

(

USED=$(("`df . --output=pcent|tr -d ' \|%'|grep -v '^[A-Z]'`"))
echo "--USED $USED % file space."
echo "---Pruning old data"
echo "data.saved/: `du -ms data.saved/|cut -f1`MB"
echo "c/olddata/: `du -ms c/olddata/|cut -f1`MB"
sleep 1

while :;
do
  USED=$(("`df . --output=pcent|tr -d ' \|%'|grep -v '^[A-Z]'`"))
  if [ "$USED" -lt 80 ]
  then
    break
  fi
#  ls log/*xz | grep xz$ | sort -n | head -n10 | xargs rm -v
  NF="`find data.saved/ c/olddata/ -type f | sort -n | head -n1`"
  if [ "$NF" == "" ]
  then
    echo "----No more old data"
    break
  fi
  S="`du -ms "\$NF\"|cut -f1`"
  echo "-Cleaning \"$NF\" ${S}MB"
  rm -rf "$NF"
  sleep .01||break
done
USED=$(("`df . --output=pcent|tr -d ' \|%'|grep -v '^[A-Z]'`"))
echo "--USED $USED % file space."
) 2>&1 | tee -a clean.log
