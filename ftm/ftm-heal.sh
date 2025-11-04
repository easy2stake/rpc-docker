#!/bin/bash

# Get project name from environment or default to ftm
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-ftm}"

# Stop the main ftm service if it's running
echo "Stopping ftm service..."
docker compose -p "$COMPOSE_PROJECT_NAME" -f docker-compose.yml down

# Run the ftm-heal service
echo "Running ftm-heal command in detached mode..."
docker compose -p "$COMPOSE_PROJECT_NAME" -f docker-compose-heal.yml run --rm -d ftm-heal

echo "ftm-heal command started in background."
