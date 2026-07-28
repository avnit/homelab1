# Homelab picks from awesome-selfhosted

Inventoried the full catalog (**1,328 services, 83 categories, 728 dockerized** — all in the interactive
`awesome-selfhosted-inventory.html`). This doc is the narrowed-down part: the services worth adding to
*your* lab, why they fit, and where each should run given what you already have (pve6 GPU/Ollama, pve7,
Unraid R530, Synology DS923+, Coolify on pve7, Pi-hole HA, n8n, media stack, Cloudflare tunnels).

## Already in your stack (tagged mint in the dashboard)

Pi-hole, n8n, Jellyfin, Sonarr, Radarr, Ollama. (Prowlarr/Bazarr/Whisparr/Coolify/LiteLLM aren't in the
catalog — awesome-selfhosted's inclusion bar excludes them — so they aren't tagged, but you run them.)

## The gaps worth filling

Each pick is present in the catalog and chosen against something specific about your setup.

### 1. Secrets — you're a security engineer with no self-hosted vault
- **Vaultwarden** ★63k — lightweight Bitwarden-compatible server. Replaces cloud password managers, keeps
  credentials on your metal. This should honestly be first.

### 2. Documents — you have real estate, a family trust, and HOA paperwork
- **Paperless-ngx** ★43k — scan-and-OCR document archive with full-text search and tagging. Purpose-built
  for exactly the Chicago/San Jose property + Bambah Family Trust + Curtner Village HOA paper trail.
- **Stirling-PDF** ★86k — self-hosted PDF toolkit (merge, split, sign, redact). Pairs with Paperless.

### 3. Photos — a real Synology Photos replacement
- **Immich** ★106k — Google Photos-style app with ML search, face recognition, mobile backup. Your pve6
  GPU can accelerate the ML jobs. Biggest quality-of-life upgrade on this list.

### 4. Personal finance — you're a FIRE/options trader
- **Firefly III** ★24k — double-entry personal finance manager with rules and reporting. Or…
- **Actual** ★27k — envelope budgeting, snappier and simpler. Firefly if you want depth (it can ingest
  your trading/cash flows via API and pair with the BigQuery/AlphaVantage data you already pull).

### 5. Feeds & bookmarks — you run an HN Digest workflow and save constantly
- **FreshRSS** ★15k (or **Miniflux** ★9k, minimalist) — self-hosted RSS aggregator. n8n can read its API,
  so your HN Digest becomes one node in a broader feed pipeline instead of a bespoke scrape.
- **Karakeep** ★26k (formerly Hoarder — AI-tagged bookmarks + full-text) or **linkding** ★11k (fast,
  no-frills). Karakeep's auto-tagging can point at your local Ollama.

### 6. Self-hosted Git — mirror the `avnit/*` repos you keep pushing
- **Gitea** ★57k / **Forgejo** (its community fork) — lightweight Git host with CI. A local mirror/backup
  of your GitHub work, and a place the Proxmox helper-scripts fork can live behind your own walls.

### 7. Ingress — complement your Cloudflare tunnels for internal services
- **Nginx Proxy Manager** ★33k — GUI reverse proxy + Let's Encrypt for LAN-only apps you don't want
  tunneled to the internet.

### 8. Dashboard — a front door for all of the above
- **Homarr** — modern homelab dashboard with service tiles + live status. (Homer and Heimdall are the
  lighter, static alternatives, also in the catalog.)

### 9. Engineer's utility box
- **IT-Tools by sharevb** / **OmniTools** — self-hosted Swiss-army utilities (encoders, converters, JWT,
  cron parsers). Handy to keep off random public sites.

## Where to run each

Reuses the two deploy paths from the repo we already built.

| Pick | Best target | Note |
|------|-------------|------|
| Vaultwarden | Proxmox LXC (community-scripts) | Tiny; back up the data volume |
| Gitea / Forgejo | Proxmox LXC (community-scripts) | Or Coolify from its container image |
| Nginx Proxy Manager | Proxmox LXC (community-scripts) | Keep separate from Cloudflare-tunnelled apps |
| FreshRSS / Miniflux | Proxmox LXC or Coolify | Wire the API into n8n |
| Paperless-ngx | Unraid Docker or Coolify | Point ingest at a Synology share |
| Immich | Unraid Docker (or Docker VM) | Use pve6 GPU for ML; large storage on Synology/Unraid |
| Firefly III / Actual | Coolify | Straight web-app deploys, Coolify's sweet spot |
| Karakeep / linkding | Coolify | Karakeep can call your local Ollama |
| Stirling-PDF | Coolify or Unraid Docker | Stateless, trivial |
| Homarr | Proxmox LXC or Coolify | Give it read access to the others |

Run the LXC ones through your **hardened community-scripts runner** (pinned fork), not raw `curl|bash`.
The Coolify ones deploy straight from the box you just stood up on pve7.

## Honest gaps the catalog *doesn't* cover

awesome-selfhosted is curated, so several homelab staples aren't in it. Worth adding anyway, flagged so
you know they're off-list:

- **Monitoring:** Uptime Kuma (status/uptime), Beszel or Netdata (host metrics), Grafana + Prometheus
  (dashboards/alerting for your cluster and trading data).
- **SSO/identity:** Authentik or Authelia — a real security-engineer add; put your internal apps behind one login.
- **Container mgmt:** Dockge or Portainer for the Unraid/Docker side.

## Using the inventory

Open `awesome-selfhosted-inventory.html` and: search by name/description/tag, filter by category, toggle
**Docker** (728 have images), **Recommended** (this list), **You run**, or **Hide mine**. Sort by stars to
see what the community actually converges on within any category. CSV (`awesome-selfhosted-inventory.csv`)
is there if you'd rather pull it into your own tooling.
