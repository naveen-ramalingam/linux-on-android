#!/bin/bash
docker run -it --rm \
  -v "$(pwd):/app" \
  -w /app \
  ubuntu:latest \
  bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y ncurses-bin coreutils procps curl; echo ''; echo '--- ENVIRONMENT READY ---'; ./linux-on-android.sh"
