#!/usr/bin/env bash

set -euo pipefail

# Docker image and container name
readonly docker_name="nginx-environment"

# Set build directory (parent dir relative to script)
readonly build_dir="$(dirname $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd))"

# Build docker image
docker build -t "$docker_name" "$build_dir"

# Run container with "--cap-add NET_ADMIN" allowing networking management
docker run -it --rm --cap-add NET_ADMIN -p 2222:22 -p 8080:80 -p 8443:443 --name "$docker_name" "$docker_name"