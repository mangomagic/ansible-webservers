#!/usr/bin/env bash

set -euo pipefail

# Docker image and container name
readonly docker_name="nginx-environment"

# Set build directory (parent dir relative to script)
readonly build_dir="$(dirname $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd))"

# SSH public key to authorize inside the container
readonly ssh_pub_key="${SSH_PUB_KEY:-$HOME/.ssh/id_ansible.pub}"

if [ ! -f "$ssh_pub_key" ]; then
    echo "ERROR: SSH public key not found at $ssh_pub_key" >&2
    echo "Generate one with: ssh-keygen -t ed25519 -f ~/.ssh/id_ansible -N ''" >&2
    exit 1
fi

# Build docker image
docker build -t "$docker_name" "$build_dir"

# Run container with SSH key mounted and ports exposed:
#   2222 -> 22  (SSH for Ansible)
#   8080 -> 80  (HTTP)
#   8443 -> 443 (HTTPS)
docker run -it --rm \
    --cap-add NET_ADMIN \
    -p 2222:22 \
    -p 8080:80 \
    -p 8443:443 \
    -v "$ssh_pub_key:/tmp/authorized_keys:ro" \
    --name "$docker_name" \
    "$docker_name"
