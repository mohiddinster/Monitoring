#!/bin/bash
HOST=`hostname -s |cut -d '-' -f1`
HOSTNAME=`hostname -s`
FILEPATH='/usr/local/scollector/info'


set -e
awk -v now=`date +%s` -v host=`hostname -s` \
'{ gsub(/^[ \t]+/, "", $2); gsub(/[ \t]+$/, "", $2); print "disk.iostats.read_request "  now " "  tolower($4) " host=" host"  " "  device_name=" tolower($3);
print "disk.iostats.read_merged "  now " "  tolower($5) " host=" host" " " device_name=" tolower($3); 
print "disk.iostats.read_sectors "  now " "  tolower($6) " host=" host"  " " device_name=" tolower($3); 
print "disk.iostats.msec_read "  now " "  tolower($7) " host=" host" "  " device_name=" tolower($3); 
print "disk.iostats.write_requests "  now " "  tolower($8) " host=" host"  " " device_name=" tolower($3); 
print "disk.iostats.write_merged "  now " "  tolower($9) " host=" host" "  " device_name=" tolower($3); 
print "disk.iostats.write_sectors "  now " "  tolower($10) " host=" host" "  " device_name=" tolower($3); 
print "disk.iostats.msec_write "  now " "  tolower($11) " host=" host" "  " device_name=" tolower($3); 
print "disk.iostats.ios_in_progress "  now " "  tolower($12) " host=" host"  " " device_name=" tolower($3); 
print "disk.iostats.msec_total "  now " "  tolower($13) " host=" host" "  " device_name=" tolower($3); 
print "disk.iostats.msec_weighted_total "  now " "  tolower($14) " host=" host"  " " device_name=" tolower($3); 
}' /proc/diskstats
