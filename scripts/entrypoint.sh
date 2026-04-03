#!/usr/bin/env bash

set -euo pipefail

# Install authorized_keys from mounted public key file
if [ -f /tmp/authorized_keys ]; then
    cp /tmp/authorized_keys /home/mangomagic/.ssh/authorized_keys
    chmod 600 /home/mangomagic/.ssh/authorized_keys
    chown mangomagic:mangomagic /home/mangomagic/.ssh/authorized_keys
else
    echo "WARNING: No SSH public key found at /tmp/authorized_keys" >&2
    echo "Mount your public key: -v ~/.ssh/id_ansible.pub:/tmp/authorized_keys:ro" >&2
fi

# Start SSH daemon
/usr/sbin/sshd

# Start nginx in foreground
exec /usr/sbin/nginx -g "daemon off;"
