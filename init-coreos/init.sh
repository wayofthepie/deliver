#!/bin/bash

launch () {
    local service=${1}
    fleetctl start ${service}
}

influxdb () {
    launch "influxdb.service"
}

cadvisor () {
    launch "cadvisor.service"
}

heapster () {
    launch "heapster.service"
}

grafana () {
    launch "grafana.service"
}

coregi () {
    launch "coregi.service"
}

jenkins () {
    launch "jenkins@1.service"
}

# Find and submit all units
find .. -type f -iname '*.service' -exec fleetctl submit {} \+

# We want to launch in this order:
#   1. influxDb
#   2. cAdvisor
#   3. heapster
#   4. grafana
#   5. coregi
#   6. jenkins

influxdb && cadvisor && heapster &&\
    grafana && coregi && jenkins && {

    echo "Successfully initialized!"

} || {

    echo "Failed to initialize :( ..."
    exit 1
}



