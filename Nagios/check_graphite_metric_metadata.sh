#!/bin/bash
##
## check_graphite_metric
##
##
## Checks for values provided by graphite interface.
## Accepts low and high ranges for warning and critical status.
##
## Depends on curl to retrieve the values from graphite interface.
##
## Specify the metric name with -m parameter, can use wildcards, but only ONE target per call.
## Retrieves current values collection with a "from" graphite parameter specifying time in the past,
##  which can be specified in parameters in the check. Useful for metrics with high intervals (e.g. 1 h)
## Ignores values received as "None" which means graphite has no points collected for the specified metric/timeframe
##
## Returns UNKNOWN status if can't retreive values from graphite.
##

# set this to your graphite settings. remove -u parameter for curl if you don't have http authentication
CURL_OPTIONS="-s -u username:password"
GRAPHITE_RENDER_URL="https://graphite.domain.com/render/"

# Declare some defaults
EXIT_NAGIOS_STATUS=-1
CHECK_OUTPUT=""
# search string in metric to replace with the HOST parameter
METRIC_HOST_MATCHSTRING="%HOST%"
# default timeframe to check graphite for values
GRAPHITE_FROM_VALUE="1hour"
# array to store metric names returned from graphite. used to keep graphite's response order
declare -a RES_METRICS
# assoc. array to store values for each metric. declared -A to iterate results and keep only the last not null value
#declare -A RES_VALUES
# counter of passed threshold parameters
HAS_LO_PARAMS=0
HAS_HI_PARAMS=0

# define exit functions for nagios
exit_ok() {
echo "OK - ${CHECK_OUTPUT}"
exit 0
}
exit_war() {
echo "WARNING - ${CHECK_OUTPUT}"
exit 1
}
exit_cri() {
echo "CRITICAL - ${CHECK_OUTPUT}"
exit 2
}
exit_unk() {
echo "UNKNOWN - ${CHECK_OUTPUT}"
exit 3
}
# May this also be the inline documentation :)
show_usage() {
cat << EOF
Usage: $0 -w <warn_lvl_high> -c <crit_lvl_high> [-H host] -m <graphite_metric_substring>
-W [value]  : Value threshold to alert as warning when graphite goes above it (hi level)
-C [value]  : Value threshold to alert as critical when graphite goes above it (hi/hi level)
-w [value]  : (Optional) Lower warning value threshold (lo level) Ignored if absent.
-c [value]  : (Optional) Lower critical value threshold (lo/lo level) Ignored if absent.
-H [host]   : (Optional) Host string in the format dc-NNN. If present, it will be replaced in the graphite metric.
-f [time]   : (Optional) Graphite-formatted time frame to check the metric for, to append to "&from=-" on the url. Defaults to "${GRAPHITE_FROM_VALUE}".
-m [metric] : Graphite metric to be checked for values. If -H is present it will replace any occurence of the string "${METRIC_HOST_MATCHSTRING}" here.
Example:
$0 -W 20 -C 40 -m "eu-002.cacti_propulsor.cacti_propulsor_cpu-0*.cpu_usage"
WARNING - eu-002.cacti_propulsor.cacti_propulsor_cpu-02.cpu_usage=30.3966666667; eu-002.cacti_propulsor.cacti_propulsor_cpu-01.cpu_usage=22.8726666667; eu-002.cacti_propulsor.cacti_propulsor_cpu-03.cpu_usage=29.4873333333; eu-002.cacti_propulsor.cacti_propulsor_cpu-04.cpu_usage=27.258;

EOF
}

while getopts ":W:C:w:c:m:H:f:h" OPT ; do
        case "${OPT}" in
        W)
                WARN_LVL_HIGH=${OPTARG}
                (( ++HAS_HI_PARAMS ))
        ;;
        C)
                CRIT_LVL_HIGH=${OPTARG}
                (( ++HAS_HI_PARAMS ))
        ;;
        w)
                WARN_LVL_LOW=${OPTARG}
                (( ++HAS_LO_PARAMS ))
        ;;
        c)
                CRIT_LVL_LOW=${OPTARG}
                (( ++HAS_LO_PARAMS ))
        ;;
        m)
                METRIC_STRING=${OPTARG}
        ;;
        H)
                HOST=${OPTARG}
        ;;
        f)
                GRAPHITE_FROM_VALUE=${OPTARG}
        ;;
        h)
                show_usage
                exit 0
        ;;
        *)
                CHECK_OUTPUT="Can't parse parameters"
                exit_unk
        ;;
        esac
done

# build base curl options for querying graphite. build the target metric passed as parameter over it
GRAPHITE_QUERY_BASE="${GRAPHITE_RENDER_URL}?format=raw&from=-${GRAPHITE_FROM_VALUE}&target="

# make sure we have all the necessary parameters
case $HAS_LO_PARAMS in
        1)
                CHECK_OUTPUT="Missing low level parameters. Passed -w=${WARN_LVL_LOW} -c=${CRIT_LVL_LOW}"
                exit_unk
        ;;
        2)
                if `awk "BEGIN {exit !(${WARN_LVL_LOW} < ${CRIT_LVL_LOW})}"` ; then
                        CHECK_OUTPUT="Low Warning threshold cannot be below critical threshold. Passed -w=${WARN_LVL_LOW} -c=${CRIT_LVL_LOW}"
                        exit_unk
                fi
        ;;
esac
case $HAS_HI_PARAMS in
        1)
                CHECK_OUTPUT="Missing high level parameters. Passed -W=${WARN_LVL_HIGH} -C=${CRIT_LVL_HIGH}"
                exit_unk
        ;;
        2)
                if `awk "BEGIN {exit !(${WARN_LVL_HIGH} > ${CRIT_LVL_HIGH})}"` ; then
                        CHECK_OUTPUT="High Warning threshold cannot be over critical threshold. Passed -W=${WARN_LVL_HIGH} -C=${CRIT_LVL_HIGH}"
                        exit_unk
                fi
        ;;
esac

## If HOST parameter is present, replace it in the metric variable
[ "$HOST" != "" ] && METRIC_STRING=$(sed "s/$METRIC_HOST_MATCHSTRING/$HOST/g" <<< $METRIC_STRING)

# Run query against graphite and store last non-none values on the array
for GRAPHITE_OUT in $(curl ${CURL_OPTIONS} ${GRAPHITE_QUERY_BASE}${METRIC_STRING} | sed 's/None//g') ; do
        GRAPHITE_METRIC=$(cut -f1 -d\| <<< $GRAPHITE_OUT | sed  's/,[0-9]*,[0-9]*,[0-9]*$//')
        RES_METRICS+=("$GRAPHITE_METRIC")
        for GRAPHITE_VALUE in $(cut -f2 -d\| <<< $GRAPHITE_OUT | sed 's/,/ /g') ; do
#               RES_VALUES[${GRAPHITE_METRIC}]=${GRAPHITE_VALUE}
          RES_VALUES="${GRAPHITE_VALUE}"
          RES_VALUES2=$(cut -f1 -d\. <<< $RES_VALUES )

        done
done

if [ $RES_VALUES2 -ge 1000000 ] ; then

  echo "CRITICAL: metadataIndexingBacklog for last 1 hr is $RES_VALUES2"

  exit 2

else

 echo "OK: metadataIndexingBacklog for last 1 hr is $RES_VALUES2"
 exit 0

fi

case $EXIT_NAGIOS_STATUS in
        0) exit_ok ;;
        1) exit_war ;;
        2) exit_cri ;;
        3) exit_unk ;;
        *) exit $EXIT_NAGIOS_STATUS ;;
esac

