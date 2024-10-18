#!/usr/bin/env bash

set -euo pipefail

/ansible-setup/scripts/ansible-setup.sh

set -x

# while true; do echo "Alive..."; sleep 10; done

/usr/sbin/nginx -g "daemon off;"