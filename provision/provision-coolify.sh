#!/usr/bin/env bash
#
# provision-coolify.sh — stand up a Coolify VM on Proxmox with NO Terraform.
#
# Runs entirely with `qm` + cloud-init on the Proxmox host, then installs Coolify
# over SSH into the new VM. No providers, no version constraints, nothing to `init`.
#
# Usage (from your Mac):
#   scp provision-coolify.sh root@192.168.0.160:/root/         # pve7
#   ssh root@192.168.0.160 'bash /root/provision-coolify.sh'
#
# Everything is overridable via env vars, e.g.:
#   ssh root@192.168.0.160 'VMID=9011 IPCONFIG=ip=dhcp bash /root/provision-coolify.sh'
#
set -euo pipefail

########################## config (edit or override via env) ##########################
VMID="${VMID:-9010}"
VMNAME="${VMNAME:-coolify}"
CORES="${CORES:-4}"
MEMORY_MB="${MEMORY_MB:-8192}"
DISK_GB="${DISK_GB:-60}"
BRIDGE="${BRIDGE:-vmbr0}"
DISK_STORAGE="${DISK_STORAGE:-local-lvm}"                 # where the VM disk lives
IPCONFIG="${IPCONFIG:-ip=192.168.0.40/24,gw=192.168.0.1}" # or: ip=dhcp
CIUSER="${CIUSER:-coolify}"
# Public key(s) that go into the VM for YOUR access. Defaults to the host's root keys.
SSH_PUBKEYS_FILE="${SSH_PUBKEYS_FILE:-/root/.ssh/authorized_keys}"
AUTO_INSTALL="${AUTO_INSTALL:-true}"                      # install Coolify after boot
#######################################################################################

IMG_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
IMG_CACHE="/var/lib/vz/template/iso/debian-12-genericcloud-amd64.qcow2"

die() { echo "ERROR: $*" >&2; exit 1; }
log() { echo -e "\n==> $*"; }

command -v qm >/dev/null || die "qm not found — run this ON a Proxmox VE host (pve6/pve7)."
qm status "$VMID" >/dev/null 2>&1 && die "VMID $VMID already exists. Re-run with VMID=<free id>."
[ -s "$SSH_PUBKEYS_FILE" ] || die "No SSH pubkeys at $SSH_PUBKEYS_FILE. Set SSH_PUBKEYS_FILE=/path/to/keys."

# Derive the VM's IP (for the SSH install step + final URL) when a static IP is given.
VM_IP=""
if [[ "$IPCONFIG" =~ ip=([0-9.]+)(/[0-9]+)? ]]; then VM_IP="${BASH_REMATCH[1]}"; fi

log "Caching Debian 12 cloud image"
mkdir -p "$(dirname "$IMG_CACHE")"
[ -f "$IMG_CACHE" ] || curl -fSL --retry 3 -o "$IMG_CACHE" "$IMG_URL"

# Ephemeral provisioning key so the host can SSH into the VM to run the installer.
PROV_KEY="$(mktemp -u /root/.coolify-prov-XXXX)"
ssh-keygen -q -t ed25519 -N "" -f "$PROV_KEY" -C "coolify-provisioner"
COMBINED_KEYS="$(mktemp)"
cat "$SSH_PUBKEYS_FILE" "${PROV_KEY}.pub" > "$COMBINED_KEYS"
cleanup() { rm -f "$PROV_KEY" "${PROV_KEY}.pub" "$COMBINED_KEYS"; }
trap cleanup EXIT

log "Creating VM $VMID ($VMNAME): ${CORES} vCPU / ${MEMORY_MB}MiB / ${DISK_GB}G on $DISK_STORAGE"
qm create "$VMID" \
  --name "$VMNAME" \
  --cores "$CORES" --memory "$MEMORY_MB" \
  --cpu host --ostype l26 \
  --net0 "virtio,bridge=$BRIDGE" \
  --scsihw virtio-scsi-single \
  --serial0 socket \
  --agent enabled=1 \
  --tags "coolify,paas,no-terraform"

log "Importing + attaching disk, resizing to ${DISK_GB}G"
qm set "$VMID" --scsi0 "${DISK_STORAGE}:0,import-from=${IMG_CACHE},discard=on,ssd=1" >/dev/null
qm disk resize "$VMID" scsi0 "${DISK_GB}G" >/dev/null
qm set "$VMID" --boot "order=scsi0" >/dev/null

log "Configuring cloud-init (user=$CIUSER, $IPCONFIG)"
qm set "$VMID" --ide2 "${DISK_STORAGE}:cloudinit" >/dev/null
qm set "$VMID" --ciuser "$CIUSER" --sshkeys "$COMBINED_KEYS" --ipconfig0 "$IPCONFIG" >/dev/null

log "Starting VM $VMID"
qm start "$VMID"

if [ "$AUTO_INSTALL" != "true" ]; then
  log "VM started. AUTO_INSTALL=false, so Coolify was not installed."
  echo "    Reach it once booted and install manually if you like."
  exit 0
fi

[ -n "$VM_IP" ] || { log "IPCONFIG is DHCP — can't auto-derive IP for the installer."; \
  echo "    Find the VM's IP (qm guest cmd $VMID network-get-interfaces), then run the Coolify installer inside it."; exit 0; }

log "Waiting for SSH on $VM_IP (cloud-init first boot, ~1-2 min)"
SSH_OPTS=(-i "$PROV_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5)
for i in $(seq 1 60); do
  if ssh "${SSH_OPTS[@]}" "${CIUSER}@${VM_IP}" true 2>/dev/null; then break; fi
  sleep 5
  [ "$i" -eq 60 ] && die "Timed out waiting for SSH on $VM_IP."
done

log "Installing Coolify inside the VM (this takes a few minutes)"
ssh "${SSH_OPTS[@]}" "${CIUSER}@${VM_IP}" 'bash -s' <<'REMOTE'
set -e
# First boot: cloud-init and apt-daily hold the dpkg lock. Wait them out before apt.
sudo cloud-init status --wait 2>/dev/null || true
sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service 2>/dev/null || true
sudo apt-get -o DPkg::Lock::Timeout=300 update
sudo apt-get -o DPkg::Lock::Timeout=300 install -y curl ca-certificates
curl -fsSL https://cdn.coollabs.io/coolify/install.sh -o /tmp/coolify-install.sh
sudo bash /tmp/coolify-install.sh
REMOTE

log "Done."
echo "    Coolify dashboard:  http://${VM_IP}:8000   (open it to create your admin user)"
echo "    SSH in:             ssh ${CIUSER}@${VM_IP}"
echo "    Destroy everything: qm stop ${VMID} && qm destroy ${VMID} --purge"
