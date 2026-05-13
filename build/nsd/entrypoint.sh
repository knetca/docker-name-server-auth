#!/bin/sh
# entrypoint.sh — nsd container entrypoint
#
# Generates nsd-control TLS keys at runtime into the shared nsd-keys volume
# if not already present. Keys are shared with nsd-manager via the volume
# so nsd-control works from both containers with matching credentials.
#
# Generating at runtime (not build time) ensures keys are always valid
# for the current volume — rebuilding without volume removal never causes
# a key mismatch.
set -eu

KEYDIR="/etc/nsd/keys"

if [ ! -f "${KEYDIR}/nsd_server.key" ]; then
    echo "Generating nsd-control keys in ${KEYDIR}"
    nsd-control-setup -d "${KEYDIR}"
fi

# Create pidfile directory — not present in Alpine by default
mkdir -p /run/nsd

exec nsd -d -c /etc/nsd/nsd.conf