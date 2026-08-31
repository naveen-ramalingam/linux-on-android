#!/bin/bash
# Docker smoke test runner

set -e

IMAGE="ubuntu:latest"
CONTAINER_NAME="linux-on-android-test"

echo "=== Linux-on-Android Docker Smoke Test ==="
echo ""

# Remove any leftover container
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Run tests in docker
docker run --rm \
    --name "$CONTAINER_NAME" \
    -v "$(pwd):/app" \
    -w /app \
    "$IMAGE" \
    bash -c "apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ncurses-bin coreutils procps curl git >/dev/null 2>&1 && chmod +x /app/tests/smoke_test.sh && /app/tests/smoke_test.sh"

EXIT_CODE=$?

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✅ All smoke tests passed inside Docker!"
else
    echo "❌ Smoke tests failed with exit code: $EXIT_CODE"
fi

exit $EXIT_CODE
)"
}

# Run the smoke tests
echo "Running smoke tests in Docker ($IMAGE)..."
echo ""

docker run --rm -it \
    --name "$CONTAINER_NAME" \
    -v "$(pwd):/app" \
    -w /app \
    "$IMAGE" \
    bash -c "$DOCKER_CMD"

EXIT_CODE=$?

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✅ All smoke tests passed!"
else
    echo "❌ Smoke tests failed with exit code: $EXIT_CODE"
fi

exit $EXIT_CODE
