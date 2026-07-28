# provision/ — no-Terraform path

For when you don't have (or don't want) a modern Terraform. These scripts run directly on the
Proxmox host with `qm` + cloud-init — no providers, no `terraform init`, nothing to version-check.

## `provision-coolify.sh`

Creates a Coolify VM and installs Coolify into it, end to end.

```sh
# from your Mac:
scp provision/provision-coolify.sh root@192.168.0.160:/root/   # pve7
ssh root@192.168.0.160 'bash /root/provision-coolify.sh'
```

Everything is overridable via env vars (defaults in the config block at the top):

```sh
ssh root@192.168.0.160 'VMID=9011 CORES=6 IPCONFIG=ip=192.168.0.41/24,gw=192.168.0.1 \
  bash /root/provision-coolify.sh'
```

What it does: caches the Debian 12 cloud image, creates the VM, imports/resizes the disk, wires up
cloud-init (your root SSH keys + a static IP), boots it, waits for SSH, then runs the official Coolify
installer inside. Prints the dashboard URL (`http://<ip>:8000`) at the end.

It does **not** touch your storage config or any other VM. Tear down with:
`qm stop <vmid> && qm destroy <vmid> --purge`.

## Requirements

- Proxmox VE 8.x/9.x (uses the `--scsi0 storage:0,import-from=` one-shot import).
- Root on the host; an SSH pubkey in `/root/.ssh/authorized_keys` (used for your access to the VM).
- Default IP is static (`192.168.0.40/24`) so the script knows where to SSH; pass `IPCONFIG=ip=dhcp`
  to use DHCP (then you'll look up the IP yourself).

## Terraform vs. this

The `terraform/` modules do the same thing more declaratively (state, `plan`, `destroy`) — use them once
you're on Terraform ≥ 1.5. This script is the escape hatch that needs none of that. Same VM either way.
