output "vm_id" {
  value = proxmox_virtual_environment_vm.sandbox.vm_id
}

output "vm_ipv4" {
  description = "Primary IPv4 (via guest agent; may show 'pending' for ~30s after boot - re-run 'terraform refresh')"
  value       = try(proxmox_virtual_environment_vm.sandbox.ipv4_addresses[1][0], "pending")
}

output "ssh_command" {
  value = try("ssh homelab@${proxmox_virtual_environment_vm.sandbox.ipv4_addresses[1][0]}", "pending")
}

output "ui_access_tunnel" {
  description = "The homelab UI binds only to the VM's localhost. Run this from your workstation, then open https://home.127-0-0-1.nip.io"
  value       = try("ssh -L 8443:127.0.0.1:443 -L 8080:127.0.0.1:80 homelab@${proxmox_virtual_environment_vm.sandbox.ipv4_addresses[1][0]}", "pending")
}

output "build_log" {
  value = "SSH in, then: tail -f /home/homelab/homelab-build.log   (build takes 15-30 min)"
}
