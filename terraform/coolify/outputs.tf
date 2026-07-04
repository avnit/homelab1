output "vm_id" {
  value = proxmox_virtual_environment_vm.coolify.vm_id
}

output "vm_ipv4" {
  description = "Primary IPv4 (via guest agent; may show 'pending' for ~30s - re-run 'terraform refresh')"
  value       = try(proxmox_virtual_environment_vm.coolify.ipv4_addresses[1][0], "pending")
}

output "dashboard_url" {
  description = "Open in a browser to finish onboarding (create admin user)"
  value       = try("http://${proxmox_virtual_environment_vm.coolify.ipv4_addresses[1][0]}:8000", "pending")
}

output "ssh_command" {
  value = try("ssh coolify@${proxmox_virtual_environment_vm.coolify.ipv4_addresses[1][0]}", "pending")
}

output "install_log" {
  value = "ssh in, then: sudo tail -f /var/log/coolify-install.log"
}
