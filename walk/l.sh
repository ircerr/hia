#!/bin/bash

cd /var/www/hia/walk/ || exit 1

while :;
do
  ./walk.sh
  if [ -x v.sh ]
  then
    ./v.sh
  fi
  if [ -x top.sh ]
  then
    ./top.sh
  fi
  if [ -x shame.sh ]
  then
    ./shame.sh
  fi
  if [ -x /var/www/hia/test/d3map/d3map.sh ]
  then
    ( cd /var/www/hia/test/d3map/ && ./d3map.sh )
  fi
#  sleep 10||break
  if [ ! -x l.sh ] \
  || [ ! -x walk.sh ]
  then
    break
  fi
done

