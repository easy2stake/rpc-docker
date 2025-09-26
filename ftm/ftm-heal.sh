#!/bin/bash

# Stop the main ftm service if it's running
echo "Stopping ftm service..."
docker compose -f docker-compose.yml down

# Run the ftm-heal service
echo "Running ftm-heal command in detached mode..."
docker compose -f docker-compose-heal.yml run --rm -d ftm-heal

echo "ftm-heal command started in background."
