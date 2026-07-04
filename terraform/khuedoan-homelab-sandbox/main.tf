terraform {
  required_version = ">= 1.5"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    username = var.proxmox_ssh_username
  }
}

# Debian 12 generic cloud image, downloaded once to the target node.
# Named .img so the bpg provider accepts the qcow2 as an "iso" content item.
resource "proxmox_virtual_environment_download_file" "debian12" {
  content_type = "iso"
  datastore_id = var.iso_datastore
  node_name    = var.node_name
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  file_name    = "debian-12-genericcloud-amd64.img"
}

# Cloud-init user-data delivered as a snippet.
# NOTE: the target datastore must have the "Snippets" content type enabled
# (Datacenter > Storage > local > Edit > Content).
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore
  node_name    = var.node_name

  source_raw {
    file_name = "khuedoan-homelab-sandbox-user-data.yaml"
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      ssh_public_key = var.ssh_public_key
      auto_build     = var.auto_build
    })
  }
}

resource "proxmox_virtual_environment_vm" "sandbox" {
  name        = var.vm_name
  description = "Isolated sandbox to evaluate khuedoan/homelab (k3d dev cluster). Managed by Terraform. Safe to destroy."
  tags        = ["sandbox", "khuedoan-homelab", "terraform"]
  node_name   = var.node_name
  on_boot     = false

  agent {
    enabled = true
  }

  cpu {
    cores = var.vcpus
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.vm_datastore
    import_from  = proxmox_virtual_environment_download_file.debian12.id
    interface    = "scsi0"
    size         = var.disk_gb
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge = var.bridge
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.vm_datastore
    interface    = "ide2"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }
}
