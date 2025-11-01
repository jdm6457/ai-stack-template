#!/bin/bash

# Define timeout and interval for checks
TIMEOUT=60
INTERVAL=3

echo "Initiating docker-compose restart..."
# Restart existing containers
docker-compose restart

echo "Waiting for all services to be in 'Up' (running) state..."

# Get the list of all service names
SERVICES=$(docker-compose ps --services)
EXIT_STATUS=0

for SERVICE_NAME in $SERVICES; do
    echo "Checking status of service: $SERVICE_NAME"
    start_time=$(date +%s)
    
    while true; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        if [ "$elapsed_time" -gt "$TIMEOUT" ]; then
            echo "Error: Timeout reached ($TIMEOUT seconds) while waiting for $SERVICE_NAME to be 'Up'." >&2
            EXIT_STATUS=1
            break 2 # Break out of both the inner and outer loops
        fi

        # Check if the service status is "running"
        # We use a filter to check the status
        IS_RUNNING=$(docker-compose ps --services --filter "status=running" | grep -q "$SERVICE_NAME"; echo $?)

        if [ "$IS_RUNNING" -eq 0 ]; then
            echo "Service $SERVICE_NAME is running."
            break
        fi

        printf "."
        sleep $INTERVAL
    done
done

if [ "$EXIT_STATUS" -eq 0 ]; then
    docker-compose ps
    echo "All docker-compose services are running and in 'Up' state."
else
    echo "Some services failed to restart properly or timed out. Check logs for details: docker-compose logs"
fi
