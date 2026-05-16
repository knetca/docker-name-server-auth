# docker-name-server-auth

NSD authoritative DNS server as a Docker Compose stack.

Serves K-Net forward and PTR zones pulled from the `knet-zones` git
repository. Four instances run on dedicated Alma 10 hosts as
`ns1–ns4.knet.ca`.

## Services

| Container | Image | Purpose |
|-----------|-------|---------|
| nsd | local build (alpine) | Authoritative DNS — serves zones from knet-zones git repo |
| nsd-manager | local build (alpine) | Zone git polling, nsd-control reload |

Both images are built locally from the same `ALPINE_TAG` pin.

## Requirements

- Docker and Docker Compose plugin
- Alma 10 host — dedicated recommended
- `network_mode: host` — DNS (UDP/53, TCP/53) requires host networking
- `knet-zones` git repository with SSH deploy key
- firewalld disabled or UDP/53 and TCP/53 explicitly permitted

## Repo structure

```
docker-name-server-auth/
├── build/
│   ├── nsd/
│   │   └── Dockerfile
│   └── manager/
│       ├── Dockerfile
│       ├── entrypoint.sh
│       └── scripts/
│           └── deploy-zones.sh
├── nsd/
│   ├── nsd.conf.d/
│   │   ├── 10-server.conf        # interfaces, control, hardening
│   │   └── 20-zones.conf         # generated zone blocks — managed by nsd-manager
│   └── custom.conf.d/
│       └── README.md             # gitignored host-specific overrides
├── manager/
│   └── ssh/
│       ├── SETUP.md
│       └── config
├── docker-compose.yml
├── .env.example
└── README.md
```

## Per-host configuration

Host-specific configuration lives in gitignored directories that survive
`git pull` without conflict:

| Directory | Purpose |
|-----------|---------|
| `nsd/custom.conf.d/` | NSD overrides — access control, additional directives |
| `manager/ssh/` | SSH deploy key and known_hosts |

## Deployment

```bash
# 1. Clone repo
git clone https://github.com/knetca/docker-name-server-auth.git /opt/docker-name-server-auth
cd /opt/docker-name-server-auth

# 2. Configure environment
cp .env.example .env
$EDITOR .env

# 3. Set up SSH deploy key
# Follow manager/ssh/SETUP.md

# 4. Set correct permissions on deploy key
chmod 600 manager/ssh/id_rsa

# 5. Build all images
docker compose build

# 6. Start stack
docker compose up -d
```

## Verification

```bash
# Health check
drill @127.0.0.1 health.check.nsd A

# Forward zone
drill @127.0.0.1 knet.ca SOA

# PTR lookup
drill @127.0.0.1 -x 66.165.220.2

# NSD status
docker exec nsd nsd-control -s 127.0.0.1@8952 status

# Manager logs
docker logs nsd-manager --follow

# Force immediate zone deploy
docker exec nsd-manager deploy-zones.sh
```

## Updating

After any change to a Dockerfile or manager scripts:

```bash
git pull
docker compose build
docker compose up -d
```

Config file changes in `nsd/nsd.conf.d/` take effect after:

```bash
docker compose restart nsd
```

To update the Alpine base, change `ALPINE_TAG` in `.env` and rebuild.

## Design decisions

### NSD over BIND

NSD is a purpose-built authoritative-only resolver — no recursive capability,
smaller attack surface than BIND, actively maintained. Zone file format is
RFC 1035 compatible — existing BIND zone files drop in without modification.

### Git-managed zones

Zones are pulled from `knet-zones` via SSH deploy key. `nsd-manager` polls
on `ZONES_CRON`, generates `nsd.conf.d/20-zones.conf` zone blocks from
enumerated `.zone` files, then issues `nsd-control reload` only when
content has changed. No AXFR from hidden primary — git is the zone
distribution mechanism.

### `nsd-control` no-TLS, loopback only

Same rationale as `docker-name-server` — eliminates key sharing between
containers, acceptable on a dedicated single-purpose host.

### `network_mode: host`

Required for DNS (UDP/53, TCP/53). All containers share the host network
stack. `nsd-control` reaches NSD at `127.0.0.1:8952` directly from
nsd-manager without cross-container networking complexity.

### Static health check zone

`health.check.nsd.` is a static zone baked into the NSD image. Health
checks are decoupled from any real zone — no operational dependency on
`knet.ca` or any other served zone being present and valid.

## Changelog

| Date | Change |
|------|--------|
| 2026-05-13 | Initial release |
