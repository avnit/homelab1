#!/usr/bin/env bash
#
# harden-community-scripts.sh
#
# Run the Proxmox VE Helper-Scripts (community-scripts/ProxmoxVE) from YOUR audited,
# pinned fork instead of blindly `curl | bash`-ing @main as root on the hypervisor.
#
# WHY: every ct/*.sh starts with
#        source <(curl -fsSL .../community-scripts/ProxmoxVE/main/misc/build.func)
#      and build.func in turn curls core.func, api.func, error_handler.func, and the
#      per-app install/*.sh -- all from `main`, at runtime, as root. A plain fork is
#      cosmetic: run the script and it STILL pulls live upstream `main`. Hardening only
#      counts if you also repoint every one of those fetches at a commit YOU reviewed.
#
# WHAT THIS DOES:
#   1. Clones YOUR fork at a specific reviewed commit into $DEST.
#   2. Rewrites every 'community-scripts/ProxmoxVE/main' reference across ct/ misc/
#      install/ vm/ tools/ to 'YOUR_FORK/PIN_SHA' -- so all runtime fetches (host-side
#      AND the in-container install phase) resolve to your immutable, audited SHA.
#   3. Verifies no upstream 'main' references remain, then hands you a tree to run from.
#
# RUN ON THE PROXMOX HOST, AS ROOT.
#
# Usage:
#   FORK_OWNER=avnit PIN_SHA=<reviewed_sha> ./harden-community-scripts.sh
#
set -euo pipefail

FORK_OWNER="${FORK_OWNER:-avnit}"
FORK_REPO="${FORK_REPO:-ProxmoxVE}"
PIN_SHA="${PIN_SHA:?Set PIN_SHA to a commit SHA from your fork that you have reviewed}"
DEST="${DEST:-/opt/community-scripts}"

UPSTREAM="community-scripts/ProxmoxVE/main"
FORK_REF="${FORK_OWNER}/${FORK_REPO}/${PIN_SHA}"

echo "==> Cloning ${FORK_OWNER}/${FORK_REPO} @ ${PIN_SHA} -> ${DEST}"
if [ -d "${DEST}/.git" ]; then
  git -C "${DEST}" fetch --all --tags --quiet
else
  git clone --quiet "https://github.com/${FORK_OWNER}/${FORK_REPO}.git" "${DEST}"
fi
git -C "${DEST}" checkout --quiet "${PIN_SHA}"
echo "    checked out $(git -C "${DEST}" rev-parse --short HEAD)"

echo "==> Repointing all upstream 'main' fetches -> ${FORK_REF}"
mapfile -t files < <(grep -rlE \
  -e "raw\.githubusercontent\.com/${UPSTREAM}" \
  -e "github\.com/community-scripts/ProxmoxVE/raw/main" \
  --exclude-dir=.git "${DEST}" || true)

for f in "${files[@]}"; do
  sed -i \
    -e "s#raw.githubusercontent.com/${UPSTREAM}#raw.githubusercontent.com/${FORK_REF}#g" \
    -e "s#github.com/community-scripts/ProxmoxVE/raw/main#github.com/${FORK_OWNER}/${FORK_REPO}/raw/${PIN_SHA}#g" \
    "$f"
done
echo "    rewrote ${#files[@]} file(s)"

echo "==> Verifying no upstream 'main' references remain..."
if grep -rn --exclude-dir=.git "community-scripts/ProxmoxVE/main" "${DEST}"; then
  echo "!!  WARNING: references above still point at upstream main -- review before running."
  exit 1
fi
echo "    OK: everything now resolves to ${FORK_REF}"

cat <<EOF

Done. Review, then run from your pinned tree. Example (Jellyfin LXC):

  less ${DEST}/ct/jellyfin.sh
  less ${DEST}/misc/build.func
  bash ${DEST}/ct/jellyfin.sh

UPDATE WORKFLOW (do this deliberately, not on autopilot):
  1) Diff upstream against your pin:
       git -C ${DEST} remote add upstream https://github.com/community-scripts/ProxmoxVE.git 2>/dev/null || true
       git -C ${DEST} fetch upstream
       git -C ${DEST} log --oneline ${PIN_SHA}..upstream/main -- ct misc install
  2) Review the changes, fast-forward your fork on GitHub.
  3) Re-run this script with the new reviewed PIN_SHA.
EOF
