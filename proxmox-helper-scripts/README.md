# Proxmox VE Helper-Scripts — hardened runner

The [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) helper-scripts are the
most directly useful repo from that video for your setup — one-command LXC/VM installers that match how you
already run Proxmox. But the default usage pattern is the exact anti-pattern a security engineer should
refuse: **`curl | bash` from a moving `main` branch, as root, on the hypervisor.**

## The actual risk (verified from the source)

Every `ct/<service>.sh` begins with:

```sh
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
```

and `build.func` then curls `core.func`, `api.func`, `error_handler.func`, `tools.func`, and the matching
`install/<app>.sh` — **all from `main`, at runtime.** Whoever controls `main` (a compromised maintainer
token, a bad merge, a malicious PR that slips through) controls what executes as root on your Proxmox host,
at the moment you run it. Forking alone does **not** fix this: the scripts hardcode the upstream URL, so a
fork you never point them at is just a bookmark.

## The fix

`harden-community-scripts.sh` runs the scripts from **your fork, pinned to a commit you reviewed**:

1. Fork `community-scripts/ProxmoxVE` on GitHub (→ `avnit/ProxmoxVE`).
2. Review a known-good commit; note its SHA.
3. On the Proxmox host, as root:
   ```sh
   FORK_OWNER=avnit PIN_SHA=<reviewed_sha> ./harden-community-scripts.sh
   ```
   It clones your fork at that SHA into `/opt/community-scripts` and rewrites **every** upstream `main`
   fetch (host-side and the in-container install phase) to `avnit/ProxmoxVE/<sha>`. After that, running any
   `ct/*.sh` pulls only code you control at an immutable ref.
4. Review the specific script + `build.func`, then run it locally.

Updates are a deliberate act: diff upstream, review, bump `PIN_SHA`, re-run. No silent drift.

## Requirements (from the repo)

Proxmox VE 8.4 / 9.0 / 9.1 / 9.2, root shell on the host, internet during install. Same as upstream —
the only thing that changes is *where the code comes from*.

## Fully air-gapped variant (optional, for the paranoid)

Repointing to a pinned fork over HTTPS is the pragmatic 90%. If you want zero runtime fetch, the func files
can be sourced from local paths and the in-container install fetch replaced with a bind-mounted copy — more
work, and it breaks cleanly on upstream changes, so most people stop at pinned-fork. Ping me if you want
that version built.
