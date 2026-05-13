# nsd — authoritative DNS server
# Plain Alpine + nsd package. Config is bind-mounted from the repo at runtime.
# Health check zone is baked in — decoupled from any real served zone.
# Runs as root — consistent with the rest of the stack.

ARG ALPINE_TAG=3.20
FROM alpine:${ALPINE_TAG}

RUN apk add --no-cache \
    nsd \
    drill

# Remove Alpine default nsd config — ours is bind-mounted at runtime.
RUN rm -f /etc/nsd/nsd.conf

# Bake in static health check zone.
# Decouples Docker healthcheck from any real zone (e.g. knet.ca).
COPY health.check.nsd.zone /etc/nsd/health.check.nsd.zone

EXPOSE 53/udp 53/tcp

# -d: run in foreground (log to stderr, captured by Docker)
# -c: config path matches bind mount in docker-compose.yml
CMD ["nsd", "-d", "-c", "/etc/nsd/nsd.conf"]
