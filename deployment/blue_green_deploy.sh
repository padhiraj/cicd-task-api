#!/bin/bash

set -e

IMAGE_NAME="cicd-task-api"
CONTAINER_BLUE="cicd-task-api-blue"
CONTAINER_GREEN="cicd-task-api-green"

BLUE_PORT=8001
GREEN_PORT=8002

NGINX_CONTAINER="cicd-nginx"

VERSION="${IMAGE_TAG:-latest}"

NEW_IMAGE="${IMAGE_NAME}:${VERSION}"

echo "========================================"
echo "BLUE-GREEN DEPLOYMENT"
echo "========================================"

echo "New image:"
echo "$NEW_IMAGE"

echo "========================================"
echo "Building Docker image"
echo "========================================"

docker build \
  -f DOCKERFILE \
  -t "$NEW_IMAGE" \
  .

echo "Docker image built successfully."

echo "========================================"
echo "Detecting active environment"
echo "========================================"

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_BLUE}$"; then

    ACTIVE="blue"
    TARGET="green"

    TARGET_CONTAINER="$CONTAINER_GREEN"
    TARGET_PORT=$GREEN_PORT

elif docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_GREEN}$"; then

    ACTIVE="green"
    TARGET="blue"

    TARGET_CONTAINER="$CONTAINER_BLUE"
    TARGET_PORT=$BLUE_PORT

else

    echo "No active environment found."

    ACTIVE="none"
    TARGET="blue"

    TARGET_CONTAINER="$CONTAINER_BLUE"
    TARGET_PORT=$BLUE_PORT

fi

echo "Active environment: $ACTIVE"
echo "Target environment: $TARGET"

echo "Target container:"
echo "$TARGET_CONTAINER"

echo "Target port:"
echo "$TARGET_PORT"

echo "========================================"
echo "Deploying to inactive environment"
echo "========================================"

if docker ps -a --format '{{.Names}}' | grep -q "^${TARGET_CONTAINER}$"; then

    echo "Removing old target container..."

    docker stop "$TARGET_CONTAINER" || true

    docker rm "$TARGET_CONTAINER" || true

fi

echo "Starting new container..."

docker run -d \
  --name "$TARGET_CONTAINER" \
  --restart unless-stopped \
  -p "$TARGET_PORT:8000" \
  "$NEW_IMAGE"

echo "New container started."

echo "========================================"
echo "Waiting for application"
echo "========================================"

sleep 5

echo "========================================"
echo "Running health check"
echo "========================================"

if curl --fail "http://localhost:${TARGET_PORT}/health"; then

    echo ""
    echo "Health check passed."

else

    echo ""
    echo "Health check failed."

    echo "Container logs:"

    docker logs "$TARGET_CONTAINER" || true

    echo "Removing failed deployment..."

    docker stop "$TARGET_CONTAINER" || true

    docker rm "$TARGET_CONTAINER" || true

    echo ""
    echo "========================================"
    echo "DEPLOYMENT FAILED"
    echo "========================================"

    exit 1

fi

echo ""
echo "========================================"
echo "Switching Nginx traffic"
echo "========================================"

if [ "$TARGET" = "blue" ]; then

    NGINX_PORT=8001

else

    NGINX_PORT=8002

fi

echo "New backend port:"
echo "$NGINX_PORT"

cat > nginx/nginx.conf <<EOF
events {}

http {
    upstream backend {
        server host.docker.internal:${NGINX_PORT};
    }

    server {
        listen 8000;

        location / {
            proxy_pass http://backend;

            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

echo "Nginx configuration updated."

echo "Reloading Nginx..."

docker exec "$NGINX_CONTAINER" nginx -s reload

echo "Nginx traffic switched."

echo "========================================"
echo "Final health check"
echo "========================================"

if curl --fail http://localhost:8000/health; then

    echo ""
    echo "========================================"
    echo "BLUE-GREEN DEPLOYMENT SUCCESSFUL"
    echo "========================================"

    echo "Active environment:"
    echo "$TARGET"

    echo "Active image:"
    echo "$NEW_IMAGE"

else

    echo ""
    echo "========================================"
    echo "FINAL HEALTH CHECK FAILED"
    echo "========================================"

    echo "Traffic switch may have failed."

    exit 1

fi