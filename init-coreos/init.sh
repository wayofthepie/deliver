#!/bin/bash

# Wrapper around journalctl that allows timeout after x seconds.
#
# $1 the timeout in seconds to wait for journactl
# $2 the service whose logs we want to tail
journal_wrap () {
    local timeout=${1}
    local service=${2}
    timeout --foreground ${timeout}s journalctl -u $service -f;
}

# Wait for a specific log entry to appear. If the
wait_for_entry () {
    local timeout=${1}
    local service=${2}
    local entry=${3}
    local status=1

    journalctl -u $service -f | while read -t ${timeout} line; do
        echo ${line}
        if [[ ${line} =~ ${entry} ]]; then
            # Vars set here do not propagate into function scope...
            touch success.tmp
            pkill -9 -P $$ journalctl
            break
        fi
    done

    # If status is 0 we have success, if not, fail.
    if [ ! -f success.tmp ]; then
        echo "Waiting for ${service} to log ${entry} timed out \\
                after ${timeout} seconds!"
        exit 1
    fi

    # Otherwise continue
    echo "${service} successfully started, continuing ..."
}

launch () {
    local service=${1}
    fleetctl start ${service}
}

influxdb () {
    launch "influxdb.service"
    wait_for_entry 300 influxdb '.*\{"status"\:"ok"\}.*'
}

cadvisor () {
    launch "cadvisor.service"
    wait_for_entry 300 cadvisor '.*Started Analyzes resource usage.*'
}

heapster () {
    launch "heapster.service"
    wait_for_entry 300 heapster ".*Starting heapster on port 8082.*"
}

grafana () {
    launch "grafana.service"
    wait_for_entry 300 grafana ".*Listening on :.*"
}

coregi () {
    launch "coregi.service"
    wait_for_entry 300 coregi ".*INFO success: coregi entered RUNNING state.*"
}

jenkins () {
    launch "jenkins@1.service"
    wait_for_entry 600 "jenkins@1" ".*INFO: Jenkins is fully up and running.*"
}


###############################################################################
# Main

# Find and submit all units
find .. -type f -iname '*.service' -exec fleetctl submit {} \+

# We want to launch in this order:
#   1. influxDb
#   2. cAdvisor
#   3. heapster
#   4. grafana
#   5. coregi
#   6. jenkins

influxdb && cadvisor && heapster && \
    grafana && coregi && jenkins && {

    echo "Successfully initialized!"

} || {

    echo "Failed to initialize :( ..."
    exit 1
}



