#!/bin/sh
# entrypoint.sh — nsd-manager container entrypoint
#
# Validates required environment, writes crontab for zone polling, runs
# initial zone deploy, then execs crond in foreground.
#
# Logging: all output goes to stdout/stderr, captured by Docker.
# crond is run with -f (foreground) and -l 8 (log level notice).
set -eu

log() { echo "$(date -Iseconds) [nsd-manager] $*"; }

# --- Validate required environment ---
: "${ZONES_REPO:?ZONES_REPO must be set in .env}"
: "${ZONES_BRANCH:=main}"
: "${ZONES_CRON:=*/5 * * * *}"

log "Starting nsd-manager"
log "Zones repo:   ${ZONES_REPO}"
log "Zones branch: ${ZONES_BRANCH}"
log "Zones cron:   ${ZONES_CRON}"

# --- SSH key permissions ---
# git/ssh will refuse keys with permissions wider than 0600
KEYFILE=/root/.ssh/id_ed25519
if [ ! -f "${KEYFILE}" ]; then
    log "ERROR: ${KEYFILE} not found — mount the deploy key"
    exit 1
fi
PERMS=$(stat -c "%a" "${KEYFILE}")
if [ "${PERMS}" != "600" ]; then
    log "ERROR: ${KEYFILE} has permissions ${PERMS} — must be 600 on the host"
    exit 1
fi

# --- Write crontab ---
# Job redirects output to /proc/1/fd/1 so Docker captures it.
cat > /etc/crontabs/root <<EOF
# nsd-manager crontab
# Zones: poll git repo, deploy on change, reload NSD
${ZONES_CRON} /usr/local/bin/deploy-zones.sh >> /proc/1/fd/1 2>&1
EOF

log "Crontab installed"

# --- Initial run ---
# Run immediately so the first cron cycle isn't delayed.
# nsd-control reload will fail softly if NSD is not yet healthy —
# the cron job succeeds on subsequent runs once NSD is up.
log "Running initial zone deploy..."
/usr/local/bin/deploy-zones.sh || log "WARNING: Initial zone deploy failed — will retry on schedule"

# --- Hand off to crond ---
log "Starting crond"
crond -l 8
tail -f /dev/null
