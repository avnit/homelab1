# homelab-selfhosted-stack

Infrastructure-as-Code and hardened runners for a **Proxmox** homelab, distilled from a
"self-hosting GitHub repos" video and adapted to a two-node cluster (pve6 / pve7).

Rather than blindly `curl | bash`-ing things onto the hypervisor, each component here is either
Terraform (reproducible, destroyable) or a security-reviewed runner.

## Contents

| Path | What it does | Runs where |
|------|--------------|-----------|
| `terraform/coolify/` | Dedicated VM running [Coolify](https://github.com/coollabsio/coolify) — a self-hostable Heroku/Netlify/Vercel PaaS | pve7 VM |
| `terraform/khuedoan-homelab-sandbox/` | Isolated eval VM for [khuedoan/homelab](https://github.com/khuedoan/homelab) (k3s/GitOps, **ALPHA**) — zero contact with prod workloads | pve6/pve7 throwaway VM |
| `proxmox-helper-scripts/` | Hardened runner for [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE): run the one-command LXC installers from **your pinned, audited fork** instead of live `main` as root | Proxmox host |

Two repos from that video are intentionally **not** here: `awesome-selfhosted` is a catalog (a
bookmark, nothing to deploy), and the deployable ones above are the parts that actually fit a Proxmox lab.

## Prerequisites

**On each Proxmox node** (one-time):
- `local` datastore has **Snippets** content enabled (Datacenter → Storage → local → Content).
- An **API token** (`user@realm!tokenid=uuid`) with VM-create, image-download, and snippet-write rights.

**On your workstation:**
- Terraform ≥ 1.5, an SSH keypair.

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
└── proxmox-helper-scripts/
```
