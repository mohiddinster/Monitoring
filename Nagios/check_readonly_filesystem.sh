#!/bin/sh
#Purpose : Monitor readonly file system. 
#Comment : You can change the location which you want to monitor file system writable or not @ FILE=''
STATE_OK=0
STATE_CRITICAL=2
FILE='/tmp/check_ro.txt'
touch $FILE >/dev/null 2>&1
RESULT=$?
if [ $RESULT -eq 0 ]; then
  echo "OK: Writable FileSystem"
  `which rm` -f $FILE
  exit $STATE_OK
else
  echo "CRITICAL: Readonly FileSystem"
  exit $STATE_CRITICAL
fi