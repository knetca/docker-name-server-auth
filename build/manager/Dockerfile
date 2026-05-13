# nsd-manager — zone sync for docker-name-server-auth
#
# Handles:
#   - Polling the knet-zones git repo and reloading NSD on change
#
# nsd-control TLS keys are generated at runtime by the nsd container
# into the shared nsd-keys volume. nsd-manager reads keys from the
# same volume to authenticate nsd-control commands.

ARG ALPINE_TAG=3.20
FROM alpine:${ALPINE_TAG}

RUN apk add --no-cache \
    git \
    nsd \
    openssl \
    dcron \
    openssh-client \
    tzdata

# Script is copied in and made executable at build time.
COPY scripts/deploy-zones.sh /usr/local/bin/deploy-zones.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x \
    /usr/local/bin/deploy-zones.sh \
    /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
