# nsd — authoritative DNS server
# Tracked config (nsd.conf, 10-server.conf) is bind-mounted from the repo.
# Runtime-generated config (20-zones.conf) lives in the nsd-runtime named
# volume shared with nsd-manager. TLS keys live in the nsd-keys named volume.
# Health check zone is baked in — decoupled from any real served zone.
# docker compose down -v produces fully clean runtime state.
# Runs as root — consistent with the rest of the stack.

ARG ALPINE_TAG=3.20
FROM alpine:${ALPINE_TAG}

RUN apk add --no-cache \
    nsd \
    drill \
    openssl

# Remove Alpine default nsd config — ours is bind-mounted at runtime.
RUN rm -f /etc/nsd/nsd.conf

# Bake in static health check zone.
# Decouples Docker healthcheck from any real zone (e.g. knet.ca).
COPY health.check.nsd.zone /etc/nsd/health.check.nsd.zone

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 53/udp 53/tcp

ENTRYPOINT ["/entrypoint.sh"]
