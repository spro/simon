#!/bin/bash

# Helper script to manage Simon routes a bit more simply
# Usage: simon-says [hostname] [destination]

# Destination should be in the form [ip]:[port] or just :[port] to imply localhost
# To remove a destination, add a "-" in front, e.g. -:5555
# To list existing destinations, leave out the last argument

HOSTNAME=$1
DESTINATION=$2

if [[ ! -z $DESTINATION ]]; then

    # If the destination starts with "-", remove it
    if [[ $DESTINATION = \-* ]]; then
        DESTINATION=${DESTINATION:1}
        REMOVE=true
    fi

    # If the destination starts with ":", prefix with the local IP
    if [[ $DESTINATION = \:* ]]; then
        DESTINATION=127.0.0.1$DESTINATION
    fi

    if [ "$REMOVE" = true ]; then
        redis-cli srem backends:$HOSTNAME $DESTINATION | echo "Not pointing $HOSTNAME to $DESTINATION"
    else
        redis-cli sadd backends:$HOSTNAME $DESTINATION | echo "Pointing $HOSTNAME to $DESTINATION"
    fi
fi

# List all assigned destinations
redis-cli smembers backends:$HOSTNAME
