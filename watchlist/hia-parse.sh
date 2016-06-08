#!/bin/bash

# HIA
# Results Parser

# Run parser scripts to further test and verify services
(
echo "hia-parse begins"

ls hia-parse-* 2>> /dev/null | \
while read F
do
  if [ -x "$F" ]
  then
    echo "-Calling $F"
    ./$F
    echo "-Completed $F"
  fi
done
echo "hia-parse complete"

) 2>&1 | tee -a hia-parse.log

#EOF#
