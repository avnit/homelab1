# homelab-selfhosted-stack

Infrastructure-as-Code and hardened runners for a **Proxmox** homelab, distilled from a
"self-hosting GitHub repos" video and adapted to a Proxmox cluster (pve6 · pve7 · the .45 node).

Rather than blindly `curl | bash`-ing things onto the hypervisor, each component here is either
Terraform (reproducible, destroyable) or a security-reviewed runner.

## Contents

| Path | What it does | Runs where |
|------|--------------|-----------|
| `terraform/coolify/` | Dedicated VM running [Coolify](https://github.com/coollabsio/coolify) — a self-hostable Heroku/Netlify/Vercel PaaS | pve7 VM |
| `terraform/khuedoan-homelab-sandbox/` | Isolated eval VM for [khuedoan/homelab](https://github.com/khuedoan/homelab) (k3s/GitOps, **ALPHA**) — zero contact with prod workloads | pve6/pve7 throwaway VM |
| `provision/provision-coolify.sh` | **No-Terraform** path: create the Coolify VM with pure `qm` + cloud-init (for old/absent Terraform) | Proxmox host |
| `proxmox-helper-scripts/` | Hardened runner for [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE): run the one-command LXC installers from **your pinned, audited fork** instead of live `main` as root | Proxmox host |
| `provision/deploy-inventory-lxc.sh` | Create LXC 320 and serve the inventory dashboard (static, lighttpd) | Proxmox host |
| `dashboard/` | Interactive inventory of all 1,328 [awesome-selfhosted](https://github.com/awesome-selfhosted/awesome-selfhosted) services + tailored picks + CSV | browser |

`awesome-selfhosted` is a catalog, not a deployable app — so rather than deploy it, `dashboard/` turns its
1,328 services into a searchable inventory with picks tailored to this lab, and `provision/deploy-inventory-lxc.sh`
serves that dashboard from an LXC.

## Prerequisites

**On each Proxmox node** (one-time):
- `local` datastore has **Snippets** content enabled (Datacenter → Storage → local → Content).
- An **API token** (`user@realm!tokenid=uuid`) with VM-create, image-download, and snippet-write rights.

**On your workstation:**
- Terraform ≥ 1.5, an SSH keypair.

## Cluster targets

| Node | IP | API endpoint |
|------|----|--------------|
| pve6 | 192.168.0.192 | `https://192.168.0.192:8006/` |
| pve7 | 192.168.0.160 | `https://192.168.0.160:8006/` |
| _.45 node_ | 192.168.0.45 | `https://192.168.0.45:8006/` |

Any module or script can target any node — set `proxmox_endpoint` + `node_name` (Terraform) or the
`root@<ip>` you SSH to (scripts). Set `node_name` to that node's real Proxmox hostname; I don't have the
hostname for the `.45` node, so fill it in there.

## Quickstart

Each Terraform module is self-contained:

```sh
cd terraform/coolify            # or terraform/khuedoan-homelab-sandbox
cp terraform.tfvars.example terraform.tfvars   # fill in endpoint, token, ssh key
terraform init
terraform apply
terraform output               # dashboard URL / ssh / build log
```

The Proxmox helper-scripts hardening runs on the host:

```sh
# after forking community-scripts/ProxmoxVE and reviewing a commit:
FORK_OWNER=avnit PIN_SHA=<reviewed_sha> ./proxmox-helper-scripts/harden-community-scripts.sh
```

See each subdirectory's `README.md` for the full rationale and caveats.

## Security notes

- **Secrets are gitignored.** Real `terraform.tfvars` (holds your Proxmox token) and all `*.tfstate`
  are excluded; only `*.tfvars.example` is tracked. Verify with `git status` before your first push.
- **khuedoan/homelab is ALPHA** and a k3s paradigm shift — the module runs it in an isolated sandbox
  only. Do not point its production/PXE path at pve6/pve7.
- **Proxmox helper-scripts** run as root on the hypervisor; the hardening runner exists so you execute
  a commit you reviewed, not a moving upstream branch.

## Layout

```
homelab-selfhosted-stack/
├── terraform/
│   ├── coolify/
│   └── khuedoan-homelab-sandbox/
├── provision/
│   ├── provision-coolify.sh
│   ├── finish-coolify-install.sh
│   └── deploy-inventory-lxc.sh
├── dashboard/                 # awesome-selfhosted inventory (html + csv) + recommendations
└── proxmox-helper-scripts/
```
