# Coolify — dedicated Proxmox VM

Provisions a dedicated VM on pve7 (or pve6) and installs [Coolify](https://github.com/coollabsio/coolify),
a self-hostable Heroku/Netlify/Vercel alternative, via its official installer.

## Why a dedicated VM

Coolify's own guidance is **one server for Coolify, separate servers for the apps it deploys**. It takes
over Docker on its host to run your applications, databases, and its Traefik proxy — so it wants a clean box,
not one shared with your existing workloads. This module gives it that. Later you can add your other
Proxmox VMs (or remote hosts) to Coolify as deployment targets over SSH.

## One-time prerequisites on the node

Same as the sandbox module:
1. **Snippets** content enabled on the `local` datastore (for cloud-init user-data).
2. An **API token** with VM create / image download / snippet write rights.

## Use

```sh
cp terraform.tfvars.example terraform.tfvars   # edit endpoint, token, ssh key, static IP
terraform init
terraform apply
```

With `auto_install = true`, the official installer runs on first boot. It's downloaded to
`/root/coolify-install.sh` first (so you can audit it) and logged to `/var/log/coolify-install.log`.

## Finish setup

```sh
terraform output dashboard_url   # http://<ip>:8000
```

Open that in a browser to create the admin account and complete onboarding. Ports in play: **8000**
(dashboard), **80/443** (Traefik proxy for deployed apps), plus 6001/6002 for realtime + terminal.

## Note on the installer

The installer is `curl | bash` as root — this module downloads it first and keeps the copy so you can
review it, but it does run the upstream `main` installer. Coolify is production-grade (unlike khuedoan's
ALPHA framework), so this is the normal, supported path. If you want the same pinned-fork treatment you're
applying to the Proxmox helper-scripts, review `/root/coolify-install.sh` before letting it run
(set `auto_install = false`, apply, SSH in, review, then `sudo systemctl start coolify-install.service`).

## Where it fits your lab

Coolify is the "give me a PaaS on my own hardware" layer: point it at a Git repo, it builds and deploys.
It complements — doesn't replace — your Proxmox/LXC workflow. Good home for the app-style things you'd
otherwise hand-wire with compose. Keep it off pve6 so it doesn't contend with your GPU/Ollama node.
