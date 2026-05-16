# SSH Deploy Key Setup

Run once on each nameserver host. The key is read-only on the knet-zones repo.
`id_rsa` is gitignored — never committed.
`known_hosts` is safe to commit on a private branch.

## 1. Generate the deploy key

```bash
ssh-keygen -t ed25519 -C "nsd-manager@$(hostname)" \
    -f manager/ssh/id_rsa -N ""
```

This creates:
- `manager/ssh/id_rsa` — private key (gitignored, bind-mounted into container)
- `manager/ssh/id_rsa.pub` — public key (add to GitHub)

## 2. Add to GitHub as a deploy key

GitHub → knet-zones repo → Settings → Deploy keys → Add deploy key

- Title: `nsd-manager-<hostname>` (e.g. `nsd-manager-ns1.knet.ca`)
- Key: paste contents of `manager/ssh/id_rsa.pub`
- Allow write access: **NO**

## 3. Capture GitHub host key

```bash
ssh-keyscan github.com > manager/ssh/known_hosts
```

Verify the fingerprint matches GitHub's published keys:
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints

## 4. Verify key works

```bash
docker run --rm -it \
    -v "$(pwd)/manager/ssh:/root/.ssh:ro" \
    alpine sh -c "apk add --no-cache git openssh-client && \
        git clone git@ssh.github.com/myorg/zone-repo.git /tmp/test && \
        echo 'SSH key works' && \
        rm -rf /tmp/test"
```

Expected: repository clones successfully, `SSH key works` printed.

## 5. Verify permissions

The entrypoint enforces 0600 on the key at startup.

```bash
chmod 600 manager/ssh/id_rsa
```
