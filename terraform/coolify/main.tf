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

resource "proxmox_virtual_environment_download_file" "debian12" {
  content_type = "iso"
  datastore_id = var.iso_datastore
  node_name    = var.node_name
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  file_name    = "debian-12-genericcloud-amd64.img"
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore
  node_name    = var.node_name

  source_raw {
    file_name = "coolify-user-data.yaml"
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      ssh_public_key = var.ssh_public_key
      auto_install   = var.auto_install
    })
  }
}

resource "proxmox_virtual_environment_vm" "coolify" {
  name        = var.vm_name
  description = "Coolify PaaS host (self-hostable Heroku/Netlify alternative). Managed by Terraform."
  tags        = ["coolify", "paas", "terraform"]
  node_name   = var.node_name
  on_boot     = true # this one is meant to stay up, unlike the sandbox

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
        address = var.ipv4_address # "dhcp" or "192.168.0.x/24"
        gateway = var.ipv4_address == "dhcp" ? null : var.ipv4_gateway
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }
}
