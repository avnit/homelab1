#!/usr/bin/env bash
#
# deploy-inventory-lxc.sh
#
# Create an LXC on a Proxmox host and serve the awesome-selfhosted inventory
# dashboard from it (static, lighttpd). This version pushes the dashboard file
# from this repo — run it from a checkout on the Proxmox host:
#
#   scp -r homelab1 root@192.168.0.45:/root/
#   ssh root@192.168.0.45 'bash /root/homelab1/provision/deploy-inventory-lxc.sh'
#
# Overridable, e.g. a fixed URL or a different HTML file:
#   CTIP=192.168.0.46/24 CTGW=192.168.0.1 bash deploy-inventory-lxc.sh
#   HTML_FILE=/path/to/index.html bash deploy-inventory-lxc.sh
#
# (A fully self-contained variant with the dashboard embedded is available too —
#  ask if you want the zero-transfer one-shot instead of a repo checkout.)
#
set -euo pipefail

CTID="${CTID:-320}"
CTNAME="${CTNAME:-selfhosted-inventory}"
CORES="${CORES:-1}"
MEMORY="${MEMORY:-512}"
DISK_GB="${DISK_GB:-4}"
BRIDGE="${BRIDGE:-vmbr0}"
ROOTFS_STORE="${ROOTFS_STORE:-local-lvm}"
TMPL_STORE="${TMPL_STORE:-local}"
CTIP="${CTIP:-dhcp}"          # or a static CIDR, e.g. 192.168.0.46/24
CTGW="${CTGW:-}"              # gateway, required if CTIP is static (e.g. 192.168.0.1)
HTML_FILE="${HTML_FILE:-$(cd "$(dirname "$0")/.." && pwd)/dashboard/index.html}"

die(){ echo "ERROR: $*" >&2; exit 1; }
log(){ echo -e "\n==> $*"; }

command -v pct >/dev/null || die "pct not found - run this ON a Proxmox host."
[ -s "$HTML_FILE" ] || die "Dashboard not found at $HTML_FILE (set HTML_FILE=/path/to/index.html)."
pct status "$CTID" >/dev/null 2>&1 && die "CT $CTID already exists. Set CTID=<free id> or destroy it first."

log "Ensuring a Debian 12 LXC template is available"
pveam update >/dev/null 2>&1 || true
TMPL_NAME="$(pveam available 2>/dev/null | awk '/debian-12-standard/{print $2}' | sort -V | tail -1)"
[ -n "$TMPL_NAME" ] || die "No debian-12-standard template found via pveam."
if ! pveam list "$TMPL_STORE" 2>/dev/null | grep -q "$TMPL_NAME"; then
  log "Downloading $TMPL_NAME"
  pveam download "$TMPL_STORE" "$TMPL_NAME"
fi
TEMPLATE="${TMPL_STORE}:vztmpl/${TMPL_NAME}"

if [ "$CTIP" = "dhcp" ]; then
  NET="name=eth0,bridge=${BRIDGE},ip=dhcp"
else
  [ -n "$CTGW" ] || die "Static CTIP given but CTGW (gateway) is empty."
  NET="name=eth0,bridge=${BRIDGE},ip=${CTIP},gw=${CTGW}"
fi

log "Creating LXC $CTID ($CTNAME): ${CORES} core / ${MEMORY}MB / ${DISK_GB}G"
pct create "$CTID" "$TEMPLATE" \
  --hostname "$CTNAME" \
  --cores "$CORES" --memory "$MEMORY" --swap "$MEMORY" \
  --rootfs "${ROOTFS_STORE}:${DISK_GB}" \
  --net0 "$NET" \
  --unprivileged 1 --onboot 1 \
  --description "awesome-selfhosted inventory dashboard (static, lighttpd)"

log "Starting CT and waiting for network"
pct start "$CTID"
for i in $(seq 1 30); do
  pct exec "$CTID" -- getent hosts deb.debian.org >/dev/null 2>&1 && break
  sleep 2
  [ "$i" -eq 30 ] && die "CT came up but has no network - check bridge/IP settings."
done

log "Installing lighttpd + deploying the dashboard"
pct exec "$CTID" -- bash -c 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq lighttpd >/dev/null'
pct exec "$CTID" -- mkdir -p /var/www/html
pct push "$CTID" "$HTML_FILE" /var/www/html/index.html
pct exec "$CTID" -- systemctl enable --now lighttpd >/dev/null 2>&1 || true
pct exec "$CTID" -- systemctl restart lighttpd

IP="$(pct exec "$CTID" -- hostname -I 2>/dev/null | awk '{print $1}')"

log "Done."
echo "    Dashboard:  http://${IP:-<ct-ip>}/"
echo "    Enter:      pct enter ${CTID}"
echo "    Remove:     pct stop ${CTID} && pct destroy ${CTID}"
