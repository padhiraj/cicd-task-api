#!/bin/bash

set -e

CONTAINER_NAME="cicd-task-api"
IMAGE_NAME="cicd-task-api"
PORT="8000"

# GitHub Actions provides this variable.
# If it is not available, use "latest".
VERSION="${IMAGE_TAG:-latest}"

NEW_IMAGE="${IMAGE_NAME}:${VERSION}"

echo "================================="
echo "Starting deployment"
echo "================================="

echo "Deploying image:"
echo "$NEW_IMAGE"

echo "================================="
echo "Building Docker image"
echo "================================="

docker build \
  -f ./DOCKERFILE \
  -t "$NEW_IMAGE" \
  .

echo "Docker image built successfully."

# Find currently running image
OLD_IMAGE=""

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    OLD_IMAGE=$(docker inspect \
      --format='{{.Config.Image}}' \
      "$CONTAINER_NAME")

    echo "Current running image:"
    echo "$OLD_IMAGE"
else
    echo "No existing container found."
fi

echo "================================="
echo "Stopping old container"
echo "================================="

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker stop "$CONTAINER_NAME" || true
    docker rm "$CONTAINER_NAME" || true
fi

echo "================================="
echo "Starting new container"
echo "================================="

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "$PORT:8000" \
  "$NEW_IMAGE"

echo "New container started."

echo "Waiting for application..."

sleep 5

echo "================================="
echo "Running health check"
echo "================================="

if curl --fail http://localhost:${PORT}/health; then

    echo ""
    echo "================================="
    echo "Deployment successful!"
    echo "================================="

    echo "Running version:"
    echo "$NEW_IMAGE"

    exit 0

fi

echo ""
echo "================================="
echo "DEPLOYMENT FAILED"
echo "================================="

echo "New container failed health check."

echo "Container logs:"

docker logs "$CONTAINER_NAME" || true

echo "================================="
echo "Starting rollback"
echo "================================="

docker stop "$CONTAINER_NAME" || true
docker rm "$CONTAINER_NAME" || true

if [ -n "$OLD_IMAGE" ]; then

    echo "Restoring previous image:"
    echo "$OLD_IMAGE"

    docker run -d \
      --name "$CONTAINER_NAME" \
      --restart unless-stopped \
      -p "$PORT:8000" \
      "$OLD_IMAGE"

    echo "Previous version restored."

    sleep 5

    echo "Checking rollback health..."

    if curl --fail http://localhost:${PORT}/health; then

        echo ""
        echo "================================="
        echo "ROLLBACK SUCCESSFUL"
        echo "================================="

        exit 1

    else

        echo ""
        echo "================================="
        echo "ROLLBACK FAILED"
        echo "================================="

        docker logs "$CONTAINER_NAME" || true

        exit 1

    fi

else

    echo "No previous version available."
    echo "Nothing to rollback to."

    exit 1

fi