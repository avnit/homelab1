# khuedoan/homelab — isolated Proxmox sandbox

Stands up **one throwaway VM** on pve6/pve7 and bootstraps [khuedoan/homelab](https://github.com/khuedoan/homelab)
as a **k3d (k3s-in-Docker) dev cluster** inside it. This is the *only* safe way to evaluate that project
against your cluster.

## Why sandbox-only (read this first)

`khuedoan/homelab` is not an app — it's an opinionated **k3s + ArgoCD GitOps framework**:

- Its **production** install path **PXE-netboots bare metal and reinstalls the OS** to bootstrap k3s
  (`metal/roles/pxe_server`). Running that flow against pve6/pve7 would try to **own and wipe your nodes**.
- Project status is **ALPHA**; upstream warns to run nothing critical on it.
- Bundled apps include **ollama** and **jellyfin**, which **overlap with your existing stack**.

This module deliberately uses only the upstream-blessed **k3d sandbox** (see `docs/installation/sandbox.md`
in the repo). Everything runs inside a single VM; `terraform destroy` removes it with no trace on your
other workloads.

## One-time prerequisites on the node

1. **Snippets enabled** on the `local` datastore (needed for cloud-init user-data):
   Datacenter → Storage → `local` → Edit → Content → tick **Snippets**.
2. **API token** with rights to create VMs, download images, and write snippets.
   Simplest for a homelab: create user `terraform@pve`, give role `PVEAdmin` on `/`, then create a token
   with *Privilege Separation unchecked*. Put `user@realm!tokenid=uuid` in `terraform.tfvars`.

## Use

```sh
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars (endpoint, token, ssh_public_key, datastore)

terraform init
terraform apply
```

`apply` provisions the VM and (with `auto_build = true`) kicks the k3d build on first boot.
The build pulls a lot and takes **15–30 min**.

## Reach it / watch it

```sh
# outputs give you these with the real IP filled in:
terraform output ssh_command        # ssh in
terraform output ui_access_tunnel   # port-forward, then open https://home.127-0-0-1.nip.io
terraform output build_log          # tail -f /home/homelab/homelab-build.log
```

The UI binds to the VM's localhost only, so use the SSH tunnel from your workstation and open
`https://home.127-0-0-1.nip.io` (ignore the cert warning — sandbox has no real certs).
Admin credentials are in the repo's `docs/installation/post-installation.md`.

If the headless build hiccups (it's ALPHA), re-run it:

```sh
sudo systemctl start homelab-build
```

## Tear down

```sh
terraform destroy
```

Deletes the VM and everything inside it (the whole k3d cluster). Nothing else on pve6/pve7 is touched.

## The pragmatic alternative

You already run a mature Proxmox lab (Ollama GPU, n8n, media stack, Pi-hole HA). Wholesale adopting a
k3s GitOps framework is a big architectural shift, not a "deploy." For your situation the higher-value
move is usually to **sandbox it to study the patterns** — the ArgoCD app-of-apps layout under `apps/`,
the per-app Helm/Kustomize structure, the secrets and backup approaches — then port the ideas you like
into how you already run things. This module gives you exactly that: a safe place to poke at it.
