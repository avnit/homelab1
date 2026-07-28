variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint, e.g. https://192.168.0.192:8006/ (pve6) or https://192.168.0.160:8006/ (pve7)"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "API token in the form user@realm!tokenid=uuid"
}

variable "proxmox_insecure" {
  type        = bool
  default     = true
  description = "Skip TLS verification (typical for homelab self-signed certs)"
}

variable "proxmox_ssh_username" {
  type        = string
  default     = "root"
  description = "SSH user the provider uses for snippet/image operations on the node"
}

variable "node_name" {
  type        = string
  default     = "pve6"
  description = "Target Proxmox node (pve6 or pve7)"
}

variable "vm_name" {
  type    = string
  default = "khuedoan-homelab-sandbox"
}

variable "vcpus" {
  type        = number
  default     = 6
  description = "khuedoan sandbox recommends 4+; 6 gives headroom for the k3d build"
}

variable "memory_mb" {
  type        = number
  default     = 16384
  description = "16 GiB recommended by upstream sandbox docs"
}

variable "disk_gb" {
  type    = number
  default = 60
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "vm_datastore" {
  type        = string
  default     = "local-lvm"
  description = "Datastore for the VM disk (e.g. local-lvm, or your NVMe thin pool)"
}

variable "iso_datastore" {
  type        = string
  default     = "local"
  description = "Datastore that holds the downloaded cloud image"
}

variable "snippet_datastore" {
  type        = string
  default     = "local"
  description = "Datastore with 'Snippets' content enabled (for cloud-init user-data)"
}

variable "ssh_public_key" {
  type        = string
  description = "Your SSH public key for the 'homelab' user inside the VM"
}

variable "auto_build" {
  type        = bool
  default     = true
  description = "Run khuedoan's k3d dev build automatically on first boot"
}
