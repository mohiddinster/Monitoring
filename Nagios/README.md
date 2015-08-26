# Usage
# check_graphite_metric_metadata modified script. Updated on 25 Aug 2015.
# This script will send notification through nagios if threshold reach mentioned value.

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
