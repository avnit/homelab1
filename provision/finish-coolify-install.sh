#!/usr/bin/env bash
#
# finish-coolify-install.sh — complete a Coolify install that was interrupted by the
# first-boot apt/dpkg lock (cloud-init + apt-daily were still holding it).
#
# The VM already exists and already trusts your SSH key, so run this FROM YOUR MAC:
#   bash finish-coolify-install.sh
#
# Override the target if needed:
#   VM_IP=192.168.0.41 bash finish-coolify-install.sh
#
set -euo pipefail

VM_IP="${VM_IP:-192.168.0.40}"
CIUSER="${CIUSER:-coolify}"
SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

echo "==> Finishing Coolify install on ${CIUSER}@${VM_IP} (waits out the boot-time apt lock)"
ssh "${SSH_OPTS[@]}" "${CIUSER}@${VM_IP}" 'bash -s' <<'REMOTE'
set -e
echo "-- waiting for cloud-init to finish --"
sudo cloud-init status --wait 2>/dev/null || true
echo "-- stopping background apt timers so they can't grab the lock --"
sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service 2>/dev/null || true
echo "-- installing prerequisites + Coolify (apt waits up to 5m for any lock) --"
sudo apt-get -o DPkg::Lock::Timeout=300 update
sudo apt-get -o DPkg::Lock::Timeout=300 install -y curl ca-certificates
curl -fsSL https://cdn.coollabs.io/coolify/install.sh -o /tmp/coolify-install.sh
sudo bash /tmp/coolify-install.sh
REMOTE

echo "==> Done. Coolify dashboard: http://${VM_IP}:8000  (create your admin user there)"
