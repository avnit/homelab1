variable "proxmox_endpoint" {
  type        = string
  description = "e.g. https://192.168.0.192:8006/ (pve6) or https://192.168.0.160:8006/ (pve7)"
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "proxmox_insecure" {
  type    = bool
  default = true
}

variable "proxmox_ssh_username" {
  type    = string
  default = "root"
}

variable "node_name" {
  type    = string
  default = "pve7" # keep it off pve6 so it doesn't compete with your GPU/Ollama node
}

variable "vm_name" {
  type    = string
  default = "coolify"
}

variable "vcpus" {
  type    = number
  default = 4
}

variable "memory_mb" {
  type        = number
  default     = 8192
  description = "Coolify min is 2 GiB; 8 GiB gives room to actually build/run apps"
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
  type    = string
  default = "local-lvm"
}

variable "iso_datastore" {
  type    = string
  default = "local"
}

variable "snippet_datastore" {
  type    = string
  default = "local"
}

variable "ipv4_address" {
  type        = string
  default     = "dhcp"
  description = "'dhcp', or a static CIDR like '192.168.0.40/24' (recommended so the dashboard URL is stable)"
}

variable "ipv4_gateway" {
  type    = string
  default = "192.168.0.1" # your UCG Fiber
}

variable "ssh_public_key" {
  type = string
}

variable "auto_install" {
  type        = bool
  default     = true
  description = "Run the official Coolify installer on first boot"
}
